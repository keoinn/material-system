<template>
  <div
    class="workflow-flow-diagram"
    :class="{ 'workflow-flow-diagram--large': large }"
  >
    <div v-if="loading" class="d-flex justify-center py-6">
      <v-progress-circular color="primary" indeterminate size="32" />
    </div>

    <div
      v-else-if="sortedSteps.length === 0"
      class="text-center text-medium-emphasis py-6"
    >
      <v-icon class="mb-2" size="large">mdi-vector-polyline</v-icon>
      <div>尚未設定流程步驟</div>
    </div>

    <template v-else>
      <div class="workflow-flow-diagram__scroll">
        <div class="workflow-flow-diagram__grid">
          <svg
            aria-hidden="true"
            class="workflow-flow-diagram__sprite"
            focusable="false"
          >
            <defs>
              <marker
                id="workflow-flow-arrow-right"
                markerHeight="6"
                markerUnits="strokeWidth"
                markerWidth="6"
                orient="auto"
                refX="10"
                refY="3"
                viewBox="0 0 10 6"
              >
                <path d="M 0 0 L 10 3 L 0 6 Z" />
              </marker>
              <marker
                id="workflow-flow-arrow-down"
                markerHeight="6"
                markerUnits="strokeWidth"
                markerWidth="6"
                orient="auto"
                refX="3"
                refY="10"
                viewBox="0 0 6 10"
              >
                <path d="M 0 0 L 6 0 L 3 10 Z" />
              </marker>
            </defs>
          </svg>

          <template
            v-for="(row, rowIndex) in nodeRows"
            :key="`row-${rowIndex}`"
          >
            <div class="workflow-flow-diagram__row-group">
              <div
                v-if="rowIndex > 0"
                :ref="el => bindBridgeEl(rowIndex, el)"
                class="workflow-flow-diagram__bridge"
              >
                <span
                  class="workflow-flow-diagram__bridge-label"
                  :style="getRowWrapLabelStyle(rowIndex, rowIndex - 1)"
                >
                  {{ getConnectorLabel(getGlobalIndex(rowIndex, 0) - 1) }}
                </span>
                <svg
                  v-if="getBridgeMetrics(rowIndex)"
                  aria-hidden="true"
                  class="workflow-flow-diagram__bridge-svg"
                  preserveAspectRatio="none"
                  :viewBox="`0 0 ${getBridgeMetrics(rowIndex).width} ${getBridgeMetrics(rowIndex).height}`"
                >
                  <path
                    class="workflow-flow-diagram__bridge-path"
                    :d="getRowWrapPath(
                      nodeRows[rowIndex - 1].length,
                      getBridgeMetrics(rowIndex).width,
                      getBridgeMetrics(rowIndex).height
                    )"
                  />
                  <polygon
                    class="workflow-flow-diagram__bridge-arrow"
                    :points="getRowWrapArrowPoints(
                      getBridgeMetrics(rowIndex).width,
                      getBridgeMetrics(rowIndex).height
                    )"
                  />
                </svg>
              </div>

              <div
                class="workflow-flow-diagram__row"
                :class="{ 'workflow-flow-diagram__row--continued': rowIndex > 0 }"
              >
              <template
                v-for="(node, colIndex) in row"
                :key="node.key"
              >
                <div
                  v-if="colIndex > 0"
                  class="workflow-flow-diagram__connector workflow-flow-diagram__connector--horizontal"
                >
                  <span class="workflow-flow-diagram__connector-label">
                    {{ getConnectorLabel(getGlobalIndex(rowIndex, colIndex) - 1) }}
                  </span>
                  <svg
                    aria-hidden="true"
                    class="workflow-flow-diagram__connector-svg"
                    preserveAspectRatio="none"
                    viewBox="0 0 100 8"
                  >
                    <line
                      class="workflow-flow-diagram__connector-stroke"
                      marker-end="url(#workflow-flow-arrow-right)"
                      x1="0"
                      x2="94"
                      y1="4"
                      y2="4"
                    />
                  </svg>
                </div>

                <div class="workflow-flow-diagram__node-cell">
                  <div
                    v-if="node.type === 'start'"
                    class="workflow-flow-diagram__node workflow-flow-diagram__node--start"
                  >
                    <div class="workflow-flow-diagram__node-order workflow-flow-diagram__node-order--label">起點</div>
                    <v-chip
                      :color="getStatusColor(workflow.initial_status_code)"
                      :size="large ? 'default' : 'small'"
                      variant="flat"
                    >
                      {{ getStatusName(workflow.initial_status_code) }}
                    </v-chip>
                  </div>

                  <div
                    v-else-if="node.type === 'end'"
                    class="workflow-flow-diagram__node workflow-flow-diagram__node--end"
                  >
                    <div class="workflow-flow-diagram__node-order workflow-flow-diagram__node-order--label">完成</div>
                    <v-chip
                      :color="getStatusColor(workflow.final_status_code)"
                      :size="large ? 'default' : 'small'"
                      variant="flat"
                    >
                      {{ getStatusName(workflow.final_status_code) }}
                    </v-chip>
                  </div>

                  <div
                    v-else
                    class="workflow-flow-diagram__node"
                    :title="getStepTooltip(node.step)"
                  >
                    <div class="workflow-flow-diagram__node-order">
                      {{ node.step.step_order }}
                    </div>
                    <div class="workflow-flow-diagram__node-title">
                      {{ node.step.step_name }}
                    </div>
                    <v-chip
                      :color="getStatusColor(node.step.status_code)"
                      class="mt-1"
                      :size="large ? 'small' : 'x-small'"
                      variant="flat"
                    >
                      {{ getStatusName(node.step.status_code) }}
                    </v-chip>
                    <v-chip
                      :color="getApproverTypeColor(node.step.approver_type)"
                      class="mt-1"
                      :size="large ? 'small' : 'x-small'"
                      variant="tonal"
                    >
                      <template #prepend>
                        <v-icon :size="large ? 'small' : 'x-small'">{{ getApproverTypeIcon(node.step.approver_type) }}</v-icon>
                      </template>
                      {{ getApproverTypeText(node.step.approver_type) }}
                    </v-chip>
                  </div>
                </div>
              </template>
            </div>
            </div>
          </template>
        </div>
      </div>

      <div
        v-if="showIncompleteEnd"
        class="workflow-flow-diagram__end-incomplete"
      >
        <div
          class="workflow-flow-diagram__node workflow-flow-diagram__node--end workflow-flow-diagram__node--end-incomplete"
          :title="incompleteEndHint"
        >
          <div class="workflow-flow-diagram__node-order workflow-flow-diagram__node-order--label">完成</div>
          <v-chip
            color="grey"
            :size="large ? 'default' : 'small'"
            variant="tonal"
          >
            {{ getStatusName(workflow.final_status_code) }}
          </v-chip>
          <div class="workflow-flow-diagram__node-hint mt-2">
            <v-icon class="mr-1" size="small">mdi-alert-outline</v-icon>
            審核流程不完整
          </div>
          <div class="text-caption text-medium-emphasis mt-1">
            {{ incompleteEndHint }}
          </div>
        </div>
      </div>

      <div
        v-if="workflow?.reject_status_code"
        class="workflow-flow-diagram__legend mt-3"
      >
        <v-icon class="mr-1" color="error" size="x-small">mdi-arrow-u-left-bottom</v-icon>
        <span class="text-caption text-medium-emphasis">
          任一步驟退回 → {{ getStatusName(workflow.reject_status_code) }}
        </span>
      </div>
    </template>
  </div>
</template>

<script setup>
  import { computed, onUnmounted, shallowRef } from 'vue'

  const COLUMNS_PER_ROW = 3
  const BRIDGE_ARROW_SIZE = 8

  const props = defineProps({
    steps: {
      type: Array,
      default: () => [],
    },
    workflow: {
      type: Object,
      default: null,
    },
    statuses: {
      type: Array,
      default: () => [],
    },
    loading: {
      type: Boolean,
      default: false,
    },
    large: {
      type: Boolean,
      default: false,
    },
  })

  const bridgeMetrics = shallowRef({})
  const bridgeObservers = new Map()

  function bindBridgeEl (rowIndex, el) {
    const existing = bridgeObservers.get(rowIndex)
    if (existing) {
      existing.disconnect()
      bridgeObservers.delete(rowIndex)
    }

    // ref 卸載時不寫入 reactive，避免 patch 期間觸發遞迴更新
    if (!el) {
      return
    }

    const updateMetrics = () => {
      const width = el.clientWidth
      const height = el.clientHeight
      const prev = bridgeMetrics.value[rowIndex]
      if (prev?.width === width && prev?.height === height) {
        return
      }
      bridgeMetrics.value = {
        ...bridgeMetrics.value,
        [rowIndex]: { width, height },
      }
    }

    const scheduleMetricsUpdate = () => {
      requestAnimationFrame(updateMetrics)
    }

    scheduleMetricsUpdate()
    const observer = new ResizeObserver(scheduleMetricsUpdate)
    observer.observe(el)
    bridgeObservers.set(rowIndex, observer)
  }

  function getBridgeMetrics (rowIndex) {
    return bridgeMetrics.value[rowIndex]
  }

  onUnmounted(() => {
    bridgeObservers.forEach(observer => observer.disconnect())
    bridgeObservers.clear()
    bridgeMetrics.value = {}
  })

  const statusMap = computed(() => {
    const map = {}
    for (const status of props.statuses) {
      map[status.status_code] = status
    }
    return map
  })

  const sortedSteps = computed(() => {
    return [...props.steps]
      .filter(step => !step.is_conditional)
      .sort((a, b) => a.step_order - b.step_order)
  })

  function getApproveTargetCode (step, index) {
    const nextStep = sortedSteps.value[index + 1]
    if (nextStep?.status_code) {
      return nextStep.status_code
    }
    if (step.approve_status_code) {
      return step.approve_status_code
    }
    return props.workflow?.final_status_code || null
  }

  /** 最後一步審核通過後是否會進入流程完成狀態 */
  const reachesFinalStatus = computed(() => {
    const finalCode = props.workflow?.final_status_code
    if (!finalCode) {
      return false
    }
    const steps = sortedSteps.value
    if (steps.length === 0) {
      return false
    }
    const lastIndex = steps.length - 1
    return getApproveTargetCode(steps[lastIndex], lastIndex) === finalCode
  })

  const showIncompleteEnd = computed(() => {
    return Boolean(
      props.workflow?.final_status_code
      && sortedSteps.value.length > 0
      && !reachesFinalStatus.value,
    )
  })

  const incompleteEndHint = computed(() => {
    const finalCode = props.workflow?.final_status_code
    const finalName = getStatusName(finalCode)
    const steps = sortedSteps.value
    if (steps.length === 0) {
      return '審核流程不完整'
    }
    const lastIndex = steps.length - 1
    const lastStep = steps[lastIndex]
    const targetCode = getApproveTargetCode(lastStep, lastIndex)
    const targetName = getStatusName(targetCode)
    return `最後一步「${lastStep.step_name}」審核通過後為「${targetName}」，未連至完成狀態「${finalName}」（${finalCode}）`
  })

  const flowNodes = computed(() => {
    const nodes = []

    if (props.workflow?.initial_status_code) {
      nodes.push({ key: 'start', type: 'start' })
    }

    sortedSteps.value.forEach((step, stepIndex) => {
      nodes.push({
        key: step.id || `step-${step.step_order}`,
        type: 'step',
        step,
        stepIndex,
      })
    })

    if (props.workflow?.final_status_code && reachesFinalStatus.value) {
      nodes.push({ key: 'end', type: 'end' })
    }

    return nodes
  })

  const nodeRows = computed(() => {
    const rows = []
    const nodes = flowNodes.value

    for (let i = 0; i < nodes.length; i += COLUMNS_PER_ROW) {
      rows.push(nodes.slice(i, i + COLUMNS_PER_ROW))
    }

    return rows
  })

  function getGlobalIndex (rowIndex, colIndex) {
    return rowIndex * COLUMNS_PER_ROW + colIndex
  }

  function getLastNodeGridColumn (nodeCount) {
    return nodeCount * 2 - 1
  }

  function getNodeColumnCenterPercent (gridColumn) {
    const centers = {
      1: 17,
      3: 53,
      5: 88,
    }
    return centers[gridColumn] || 17
  }

  function getLastNodeCenterPercent (nodeCount) {
    return getNodeColumnCenterPercent(getLastNodeGridColumn(nodeCount))
  }

  function getConnectorWidthPx () {
    return props.large ? 88 : 72
  }

  function getNodeCenterPx (width, gridColumn) {
    const gap = 8
    const connector = getConnectorWidthPx()
    const nodeWidth = (width - (2 * gap) - (2 * connector)) / 3

    if (gridColumn === 1) {
      return nodeWidth / 2
    }
    if (gridColumn === 3) {
      return nodeWidth + gap + connector + (nodeWidth / 2)
    }
    if (gridColumn === 5) {
      return (2 * nodeWidth) + (2 * gap) + (2 * connector) + (nodeWidth / 2)
    }
    return nodeWidth / 2
  }

  function getRowWrapEndY (height) {
    return height - BRIDGE_ARROW_SIZE - 1
  }

  function getRowWrapPath (nodeCount, width, height) {
    if (!width || !height) {
      return ''
    }

    const xEnd = getNodeCenterPx(width, getLastNodeGridColumn(nodeCount))
    const xStart = getNodeCenterPx(width, 1)
    const yStart = 14
    const yEnd = getRowWrapEndY(height)
    const yMid = (yStart + yEnd) / 2

    return [
      `M ${xEnd.toFixed(2)} ${yStart.toFixed(2)}`,
      `C ${xEnd.toFixed(2)} ${yMid.toFixed(2)}, ${xStart.toFixed(2)} ${yMid.toFixed(2)}, ${xStart.toFixed(2)} ${yEnd.toFixed(2)}`,
      `L ${xStart.toFixed(2)} ${(height - 1).toFixed(2)}`,
    ].join(' ')
  }

  function getRowWrapArrowPoints (width, height) {
    if (!width || !height) {
      return ''
    }

    const x = getNodeCenterPx(width, 1)
    const yTip = height - 1
    const yBase = getRowWrapEndY(height)
    const halfWidth = 5

    return [
      `${(x - halfWidth).toFixed(2)},${yBase.toFixed(2)}`,
      `${(x + halfWidth).toFixed(2)},${yBase.toFixed(2)}`,
      `${x.toFixed(2)},${yTip.toFixed(2)}`,
    ].join(' ')
  }

  function getRowWrapLabelStyle (bridgeRowIndex, previousRowIndex) {
    const nodeCount = nodeRows.value[previousRowIndex].length
    const metrics = bridgeMetrics.value[bridgeRowIndex]
    const gridColumn = getLastNodeGridColumn(nodeCount)

    if (metrics?.width) {
      return {
        left: `${getNodeCenterPx(metrics.width, gridColumn)}px`,
        transform: 'translateX(-50%)',
      }
    }

    return {
      left: `${getLastNodeCenterPercent(nodeCount)}%`,
      transform: 'translateX(-50%)',
    }
  }

  function getConnectorLabel (nodeIndex) {
    const node = flowNodes.value[nodeIndex]
    if (!node) {
      return ''
    }
    if (node.type === 'start') {
      return '提交'
    }
    if (node.type === 'step') {
      return `通過 → ${getApproveTargetLabel(node.step, node.stepIndex)}`
    }
    return ''
  }

  function getStatusName (statusCode) {
    if (!statusCode) {
      return '-'
    }
    const status = statusMap.value[statusCode]
    return status?.status_name || statusCode
  }

  function getStatusColor (statusCode) {
    const status = statusMap.value[statusCode]
    return status?.color || 'grey'
  }

  function getApproverTypeText (type) {
    const texts = {
      USER: '指定使用者',
      ROLE: '指定角色',
      DEPARTMENT: '指定部門',
      AUTO: '自動通過',
    }
    return texts[type] || type || '-'
  }

  function getApproverTypeColor (type) {
    const colors = {
      USER: 'info',
      ROLE: 'primary',
      DEPARTMENT: 'teal',
      AUTO: 'grey',
    }
    return colors[type] || 'grey'
  }

  function getApproverTypeIcon (type) {
    const icons = {
      USER: 'mdi-account',
      ROLE: 'mdi-shield-account',
      DEPARTMENT: 'mdi-office-building',
      AUTO: 'mdi-lightning-bolt',
    }
    return icons[type] || 'mdi-help-circle-outline'
  }

  function getApproveTargetLabel (step, index) {
    const targetCode = getApproveTargetCode(step, index)
    if (targetCode) {
      return getStatusName(targetCode)
    }
    return '下一步'
  }

  function getStepTooltip (step) {
    const parts = [
      `步驟 ${step.step_order}：${step.step_name}`,
      `狀態：${getStatusName(step.status_code)}`,
      `審核：${getApproverTypeText(step.approver_type)}`,
    ]
    if (step.approve_status_code) {
      parts.push(`通過 → ${getStatusName(step.approve_status_code)}`)
    }
    if (step.reject_status_code) {
      parts.push(`退回 → ${getStatusName(step.reject_status_code)}`)
    }
    return parts.join('\n')
  }
</script>

<style scoped>
.workflow-flow-diagram__scroll {
  overflow: auto;
  padding-bottom: 4px;
}

.workflow-flow-diagram--large .workflow-flow-diagram__scroll {
  max-height: min(70vh, 560px);
}

.workflow-flow-diagram__grid {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.workflow-flow-diagram__sprite marker path {
  fill: rgba(var(--v-theme-success), 0.85);
}

.workflow-flow-diagram__sprite {
  position: absolute;
  width: 0;
  height: 0;
  overflow: visible;
  pointer-events: none;
}

.workflow-flow-diagram__row-group {
  position: relative;
  display: flex;
  flex-direction: column;
  isolation: isolate;
  width: 100%;
}

.workflow-flow-diagram__bridge {
  position: relative;
  z-index: 5;
  flex-shrink: 0;
  width: 100%;
  height: calc(84px + 14px);
  margin: 4px 0 0;
  pointer-events: none;
}

.workflow-flow-diagram--large .workflow-flow-diagram__bridge {
  height: calc(92px + 14px);
}

.workflow-flow-diagram__bridge-svg {
  position: relative;
  z-index: 5;
  display: block;
  overflow: visible;
  width: 100%;
  height: 100%;
}

.workflow-flow-diagram__bridge-path,
.workflow-flow-diagram__connector-stroke {
  fill: none;
  stroke: rgba(var(--v-theme-success), 0.85);
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-width: 2;
  vector-effect: non-scaling-stroke;
}

.workflow-flow-diagram__bridge-arrow {
  fill: rgba(var(--v-theme-success), 0.85);
  stroke: none;
}

.workflow-flow-diagram__bridge-label {
  position: absolute;
  top: 0;
  z-index: 1;
  max-width: 120px;
  color: rgba(var(--v-theme-on-surface), 0.65);
  font-size: 11px;
  line-height: 1.3;
  text-align: center;
  transform: translateX(-50%);
  word-break: break-word;
  pointer-events: auto;
}

.workflow-flow-diagram--large .workflow-flow-diagram__bridge-label {
  font-size: 12px;
}

.workflow-flow-diagram__row {
  position: relative;
  z-index: 0;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr) auto minmax(0, 1fr);
  gap: 8px;
  align-items: center;
  width: 100%;
}

.workflow-flow-diagram__row--continued {
  margin-top: -2px;
}

.workflow-flow-diagram__node-cell {
  position: relative;
  z-index: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 0;
}

.workflow-flow-diagram__node {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  min-height: 120px;
  padding: 12px 10px;
  border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  border-radius: 10px;
  background: rgb(var(--v-theme-surface));
  text-align: center;
  box-sizing: border-box;
}

.workflow-flow-diagram--large .workflow-flow-diagram__node {
  min-height: 140px;
  padding: 16px 12px;
}

.workflow-flow-diagram__node--start,
.workflow-flow-diagram__node--end {
  justify-content: center;
}

.workflow-flow-diagram__node--start {
  border-style: dashed;
}

.workflow-flow-diagram__node--end {
  border-color: rgb(var(--v-theme-success));
  background: rgba(var(--v-theme-success), 0.06);
}

.workflow-flow-diagram__end-incomplete {
  display: flex;
  justify-content: center;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px dashed rgba(var(--v-border-color), var(--v-border-opacity));
}

.workflow-flow-diagram__node--end-incomplete {
  max-width: 320px;
  border-color: rgba(var(--v-border-color), var(--v-border-opacity));
  border-style: dashed;
  background: rgba(var(--v-theme-on-surface), 0.04);
  opacity: 0.85;
}

.workflow-flow-diagram__node-hint {
  display: inline-flex;
  align-items: center;
  color: rgb(var(--v-theme-warning));
  font-size: 12px;
  font-weight: 600;
  line-height: 1.35;
}

.workflow-flow-diagram--large .workflow-flow-diagram__node-hint {
  font-size: 13px;
}

.workflow-flow-diagram__node-order {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  margin-bottom: 6px;
  border-radius: 50%;
  background: rgba(var(--v-theme-primary), 0.12);
  color: rgb(var(--v-theme-primary));
  font-size: 12px;
  font-weight: 600;
}

.workflow-flow-diagram--large .workflow-flow-diagram__node-order {
  width: 28px;
  height: 28px;
  font-size: 13px;
}

.workflow-flow-diagram__node-order.workflow-flow-diagram__node-order--label {
  width: auto;
  min-width: 36px;
  padding: 0 8px;
  border-radius: 6px;
  box-sizing: border-box;
  line-height: 1;
  white-space: nowrap;
}

.workflow-flow-diagram--large .workflow-flow-diagram__node-order.workflow-flow-diagram__node-order--label {
  width: auto;
  min-width: 40px;
  height: 28px;
  padding: 0 9px;
  border-radius: 7px;
}

.workflow-flow-diagram__node-title {
  font-size: 13px;
  font-weight: 600;
  line-height: 1.35;
  word-break: break-word;
}

.workflow-flow-diagram--large .workflow-flow-diagram__node-title {
  font-size: 14px;
}

.workflow-flow-diagram__connector {
  position: relative;
  z-index: 3;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  align-self: center;
}

.workflow-flow-diagram__connector--horizontal {
  width: 72px;
  height: 8px;
  overflow: visible;
}

.workflow-flow-diagram--large .workflow-flow-diagram__connector--horizontal {
  width: 88px;
}

.workflow-flow-diagram__connector-svg {
  display: block;
  overflow: visible;
  width: 100%;
  height: 100%;
}

.workflow-flow-diagram__connector-label {
  position: absolute;
  bottom: calc(100% + 6px);
  left: 50%;
  max-width: 120px;
  color: rgba(var(--v-theme-on-surface), 0.65);
  font-size: 11px;
  line-height: 1.3;
  text-align: center;
  transform: translateX(-50%);
  word-break: break-word;
  white-space: normal;
}

.workflow-flow-diagram--large .workflow-flow-diagram__connector-label {
  font-size: 12px;
}

.workflow-flow-diagram__legend {
  display: flex;
  align-items: center;
  padding-top: 8px;
  border-top: 1px dashed rgba(var(--v-border-color), var(--v-border-opacity));
}
</style>
