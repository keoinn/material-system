import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

const STORAGE_KEY = 'batch_material_drafts_v1'

export const useBatchMaterialApplicationsStore = defineStore('batchMaterialApplications', () => {
  const drafts = ref([])
  const selectedDraftId = ref(null)
  const counter = ref(1)

  const selectedDraft = computed(() => {
    return drafts.value.find(item => item.id === selectedDraftId.value) || null
  })

  const draftCount = computed(() => {
    return drafts.value.filter(item => item.status === 'draft').length
  })

  function saveToStorage () {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        drafts: drafts.value,
        selectedDraftId: selectedDraftId.value,
        counter: counter.value,
      }))
    } catch (error) {
      console.error('儲存批次草稿失敗', error)
    }
  }

  function loadFromStorage () {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (!stored) return
      const parsed = JSON.parse(stored)
      drafts.value = Array.isArray(parsed.drafts) ? parsed.drafts : []
      selectedDraftId.value = parsed.selectedDraftId || null
      counter.value = Number.isInteger(parsed.counter) ? parsed.counter : 1
    } catch (error) {
      console.error('載入批次草稿失敗', error)
      drafts.value = []
      selectedDraftId.value = null
      counter.value = 1
    }
  }

  function createDraft () {
    const newDraft = {
      id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
      name: `物料申請草稿 ${String(counter.value).padStart(2, '0')}`,
      status: 'draft',
      recordId: null,
      values: {},
      updatedAt: new Date().toISOString(),
    }
    drafts.value.unshift(newDraft)
    selectedDraftId.value = newDraft.id
    counter.value += 1
    saveToStorage()
    return newDraft
  }

  function duplicateDraft (draftId) {
    const source = drafts.value.find(item => item.id === draftId)
    if (!source) return null

    const clonedDraft = {
      id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
      name: `物料申請草稿 ${String(counter.value).padStart(2, '0')}`,
      status: 'draft',
      recordId: null,
      values: JSON.parse(JSON.stringify(source.values || {})),
      updatedAt: new Date().toISOString(),
    }

    drafts.value.unshift(clonedDraft)
    selectedDraftId.value = clonedDraft.id
    counter.value += 1
    saveToStorage()
    return clonedDraft
  }

  function hasDraft (draftId) {
    return drafts.value.some(item => item.id === draftId)
  }

  function selectDraft (draftId) {
    if (!draftId) {
      selectedDraftId.value = null
      saveToStorage()
      return
    }
    if (hasDraft(draftId)) {
      selectedDraftId.value = draftId
      saveToStorage()
    }
  }

  function updateDraftValues (draftId, values) {
    const target = drafts.value.find(item => item.id === draftId)
    if (!target) return
    target.values = { ...values }
    target.updatedAt = new Date().toISOString()
    saveToStorage()
  }

  function updateDraftName (draftId, name) {
    const target = drafts.value.find(item => item.id === draftId)
    if (!target) return
    target.name = name
    target.updatedAt = new Date().toISOString()
    saveToStorage()
  }

  function removeDraft (draftId) {
    drafts.value = drafts.value.filter(item => item.id !== draftId)
    if (selectedDraftId.value === draftId) {
      selectedDraftId.value = drafts.value[0]?.id || null
    }
    saveToStorage()
  }

  function markSubmitted (draftId, recordId) {
    const target = drafts.value.find(item => item.id === draftId)
    if (!target) return
    target.status = 'submitted'
    target.recordId = recordId || 'N/A'
    target.updatedAt = new Date().toISOString()
    saveToStorage()
  }

  loadFromStorage()

  return {
    drafts,
    selectedDraftId,
    selectedDraft,
    draftCount,
    createDraft,
    duplicateDraft,
    hasDraft,
    selectDraft,
    updateDraftName,
    updateDraftValues,
    removeDraft,
    markSubmitted,
    saveToStorage,
  }
})
