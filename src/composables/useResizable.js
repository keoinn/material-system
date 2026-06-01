import { computed, onUnmounted, reactive, ref } from 'vue'

function resolveLimit (value) {
  return typeof value === 'function' ? value() : value
}

function clamp (value, min, max) {
  let result = value
  if (min != null) {
    result = Math.max(result, min)
  }
  if (max != null) {
    result = Math.min(result, max)
  }
  return result
}

/**
 * 可拖曳移動、調整寬高的浮動視窗 composable
 */
export function useResizable (initialSize, constraints = {}) {
  const size = reactive({
    width: initialSize.width,
    height: initialSize.height,
  })
  const position = reactive({
    x: null,
    y: null,
  })
  const isResizing = ref(false)
  const isDragging = ref(false)
  const pointer = reactive({ x: 0, y: 0 })

  const isInteracting = computed(() => isResizing.value || isDragging.value)

  let shellEl = null
  let overlayEl = null
  let activeMode = null // 'drag' | 'resize'
  let activeDirection = null
  let startPointer = { x: 0, y: 0 }
  let startSize = { width: 0, height: 0 }
  let startPosition = { x: 0, y: 0 }

  function getViewportMargin () {
    return constraints.viewportMargin ?? 16
  }

  function getSizeConstraints (posX = position.x, posY = position.y) {
    const margin = getViewportMargin()
    const maxHeight = resolveLimit(constraints.maxHeight ?? window.innerHeight - margin * 2)
    let maxWidth = resolveLimit(constraints.maxWidth ?? Infinity)

    if (posX != null) {
      maxWidth = Math.min(maxWidth, window.innerWidth - posX - margin)
    }

    if (posY != null) {
      const maxHeightByPosition = window.innerHeight - posY - margin
      return {
        minWidth: constraints.minWidth ?? 0,
        maxWidth: Math.max(constraints.minWidth ?? 0, maxWidth),
        minHeight: constraints.minHeight ?? 0,
        maxHeight: Math.max(constraints.minHeight ?? 0, Math.min(maxHeight, maxHeightByPosition)),
      }
    }

    return {
      minWidth: constraints.minWidth ?? 0,
      maxWidth,
      minHeight: constraints.minHeight ?? 0,
      maxHeight,
    }
  }

  function clampPosition () {
    if (position.x == null || position.y == null) {
      return
    }

    const margin = getViewportMargin()
    const minVisible = constraints.minVisible ?? 96

    position.x = clamp(
      position.x,
      margin - size.width + minVisible,
      window.innerWidth - minVisible - margin,
    )
    position.y = clamp(
      position.y,
      margin,
      window.innerHeight - minVisible - margin,
    )
  }

  function applyStoredLayout (data) {
    if (typeof data.width === 'number') {
      size.width = data.width
    }
    if (typeof data.height === 'number') {
      size.height = data.height
    }
    if (typeof data.x === 'number' && typeof data.y === 'number') {
      position.x = data.x
      position.y = data.y
    }

    clampPosition()

    const limits = getSizeConstraints(position.x, position.y)
    size.width = clamp(size.width, limits.minWidth, limits.maxWidth)
    size.height = clamp(size.height, limits.minHeight, limits.maxHeight)
    clampPosition()
  }

  function loadFromStorage () {
    const key = constraints.storageKey
    if (!key) {
      return false
    }

    try {
      const raw = localStorage.getItem(key)
      if (!raw) {
        return false
      }

      const data = JSON.parse(raw)
      if (!data || typeof data !== 'object') {
        return false
      }

      applyStoredLayout(data)
      if (constraints.applyExtraStorage) {
        constraints.applyExtraStorage(data)
      }
      return position.x != null && position.y != null
    } catch {
      return false
    }
  }

  function saveToStorage () {
    const key = constraints.storageKey
    if (!key || position.x == null || position.y == null) {
      return
    }

    try {
      const payload = {
        width: Math.round(size.width),
        height: Math.round(size.height),
        x: Math.round(position.x),
        y: Math.round(position.y),
      }

      if (constraints.getExtraStorage) {
        Object.assign(payload, constraints.getExtraStorage())
      }

      localStorage.setItem(key, JSON.stringify(payload))
    } catch {
      // ignore quota / private mode errors
    }
  }

  function ensurePositionInitialized () {
    if (position.x != null && position.y != null) {
      return
    }

    if (loadFromStorage()) {
      return
    }

    const margin = getViewportMargin()
    position.x = Math.max(margin, (window.innerWidth - size.width) / 2)
    position.y = Math.max(margin, (window.innerHeight - size.height) / 2)
    clampPosition()
  }

  const shellStyle = computed(() => {
    if (position.x == null || position.y == null) {
      return {
        width: `${Math.round(size.width)}px`,
        height: `${Math.round(size.height)}px`,
      }
    }

    return {
      position: 'fixed',
      left: `${Math.round(position.x)}px`,
      top: `${Math.round(position.y)}px`,
      width: `${Math.round(size.width)}px`,
      height: `${Math.round(size.height)}px`,
      zIndex: constraints.zIndex ?? 1,
    }
  })

  function updatePointerPosition (event) {
    pointer.x = event.clientX
    pointer.y = event.clientY
  }

  function setBodyInteractionState (cursor) {
    document.body.classList.add('resizable-surface-active')
    if (cursor) {
      document.body.style.cursor = cursor
    }
    document.body.style.userSelect = 'none'
  }

  function clearBodyInteractionState () {
    document.body.classList.remove('resizable-surface-active')
    document.body.style.removeProperty('cursor')
    document.body.style.removeProperty('user-select')
  }

  function onPointerMove (event) {
    if (!activeMode) {
      return
    }

    updatePointerPosition(event)

    const deltaX = event.clientX - startPointer.x
    const deltaY = event.clientY - startPointer.y

    if (activeMode === 'drag') {
      position.x = startPosition.x + deltaX
      position.y = startPosition.y + deltaY
      clampPosition()
      return
    }

    if (activeMode === 'resize' && activeDirection) {
      const limits = getSizeConstraints(startPosition.x, startPosition.y)
      let nextWidth = startSize.width
      let nextHeight = startSize.height
      let nextX = startPosition.x
      let nextY = startPosition.y

      if (activeDirection.includes('e')) {
        nextWidth = startSize.width + deltaX
      }
      if (activeDirection.includes('w')) {
        nextWidth = startSize.width - deltaX
        nextX = startPosition.x + deltaX
      }
      if (activeDirection.includes('s')) {
        nextHeight = startSize.height + deltaY
      }
      if (activeDirection.includes('n')) {
        nextHeight = startSize.height - deltaY
        nextY = startPosition.y + deltaY
      }

      nextWidth = clamp(nextWidth, limits.minWidth, limits.maxWidth)
      nextHeight = clamp(nextHeight, limits.minHeight, limits.maxHeight)

      if (activeDirection.includes('w')) {
        nextX = startPosition.x + (startSize.width - nextWidth)
      }
      if (activeDirection.includes('n')) {
        nextY = startPosition.y + (startSize.height - nextHeight)
      }

      size.width = nextWidth
      size.height = nextHeight
      position.x = nextX
      position.y = nextY
      clampPosition()
    }
  }

  function stopInteraction () {
    if (!activeMode) {
      return
    }

    activeMode = null
    activeDirection = null
    isResizing.value = false
    isDragging.value = false
    clearBodyInteractionState()

    window.removeEventListener('pointermove', onPointerMove)
    window.removeEventListener('pointerup', stopInteraction)
    window.removeEventListener('pointercancel', stopInteraction)

    saveToStorage()
  }

  function beginInteraction (mode, event, direction = null) {
    stopInteraction()
    ensurePositionInitialized()

    activeMode = mode
    activeDirection = direction
    isResizing.value = mode === 'resize'
    isDragging.value = mode === 'drag'
    startPointer = { x: event.clientX, y: event.clientY }
    startSize = { width: size.width, height: size.height }
    startPosition = { x: position.x, y: position.y }
    updatePointerPosition(event)

    const cursorMap = {
      e: 'ew-resize',
      w: 'ew-resize',
      s: 'ns-resize',
      n: 'ns-resize',
      se: 'nwse-resize',
      sw: 'nesw-resize',
      ne: 'nesw-resize',
      nw: 'nwse-resize',
      drag: 'move',
    }
    setBodyInteractionState(cursorMap[direction || mode] || 'default')

    window.addEventListener('pointermove', onPointerMove)
    window.addEventListener('pointerup', stopInteraction)
    window.addEventListener('pointercancel', stopInteraction)

    if (event.target?.setPointerCapture) {
      try {
        event.target.setPointerCapture(event.pointerId)
      } catch {
        // ignore capture errors
      }
    }
  }

  function startResize (direction, event) {
    beginInteraction('resize', event, direction)
  }

  function startDrag (event) {
    if (event.button !== 0) {
      return
    }
    if (event.target.closest('button, .v-btn, a, input, textarea, select, label')) {
      return
    }
    beginInteraction('drag', event)
  }

  function bindOverlayHost () {
    overlayEl = shellEl?.closest('.v-overlay__content') ?? null
    overlayEl?.classList.add('resizable-overlay-host')
  }

  function unbindOverlayHost () {
    overlayEl?.classList.remove('resizable-overlay-host')
    overlayEl = null
  }

  function registerSurface (el) {
    shellEl = el
    ensurePositionInitialized()
    bindOverlayHost()
  }

  function clearSurfacePosition () {
    stopInteraction()
    if (position.x != null && position.y != null) {
      saveToStorage()
    }
    position.x = null
    position.y = null
    unbindOverlayHost()
    shellEl = null
  }

  onUnmounted(() => {
    stopInteraction()
    unbindOverlayHost()
  })

  return {
    size,
    position,
    isResizing,
    isDragging,
    isInteracting,
    pointer,
    shellStyle,
    startResize,
    startDrag,
    registerSurface,
    clearSurfacePosition,
    persistLayout: saveToStorage,
  }
}
