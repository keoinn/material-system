/**
 * Applications Store
 * 物料申請資料管理
 */
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'

export const useApplicationsStore = defineStore('applications', () => {
  // State
  const applications = ref([])
  const codeCounter = ref({})
  const loading = ref(false)

  // Getters
  const pendingApplications = computed(() =>
    applications.value.filter(app => app.status === 'PENDING'),
  )

  const approvedApplications = computed(() =>
    applications.value.filter(app => app.status === 'APPROVED'),
  )

  const rejectedApplications = computed(() =>
    applications.value.filter(app => app.status === 'REJECTED'),
  )

  const pendingCount = computed(() => pendingApplications.value.length)

  // Actions
  function loadApplications () {
    try {
      const stored = localStorage.getItem('applications_v35')
      if (stored) {
        applications.value = JSON.parse(stored)
      }
    } catch (error) {
      console.error('載入申請資料失敗', error)
      applications.value = []
    }
  }

  function saveApplications () {
    try {
      localStorage.setItem('applications_v35', JSON.stringify(applications.value))
    } catch (error) {
      console.error('儲存申請資料失敗', error)
    }
  }

  function loadCodeCounter () {
    try {
      const stored = localStorage.getItem('codeCounter_v35')
      if (stored) {
        codeCounter.value = JSON.parse(stored)
      }
    } catch (error) {
      console.error('載入編碼計數器失敗', error)
      codeCounter.value = {}
    }
  }

  function saveCodeCounter () {
    try {
      localStorage.setItem('codeCounter_v35', JSON.stringify(codeCounter.value))
    } catch (error) {
      console.error('儲存編碼計數器失敗', error)
    }
  }

  function generateItemCode (mainCategory, subCategory, specCategory) {
    if (!mainCategory || !subCategory || !specCategory) {
      return null
    }

    const key = `${mainCategory}${subCategory}.${specCategory}`
    let counter = codeCounter.value[key] || 0
    counter++
    codeCounter.value[key] = counter
    saveCodeCounter()

    const serial = String(counter).padStart(5, '0')
    return `${mainCategory}${subCategory}.${specCategory}.${serial}`
  }

  function addApplication (applicationData) {
    const application = {
      id: Date.now().toString(),
      submitDate: new Date().toISOString(),
      status: 'PENDING',
      ...applicationData,
    }
    applications.value.push(application)
    saveApplications()
    return application
  }

  function updateApplication (id, updates) {
    const index = applications.value.findIndex(app => app.id === id)
    if (index !== -1) {
      applications.value[index] = { ...applications.value[index], ...updates }
      saveApplications()
      return applications.value[index]
    }
    return null
  }

  function approveApplication (id, approver) {
    return updateApplication(id, {
      status: 'APPROVED',
      approvalDate: new Date().toISOString(),
      approver,
    })
  }

  function rejectApplication (id, reason, approver) {
    return updateApplication(id, {
      status: 'REJECTED',
      rejectDate: new Date().toISOString(),
      rejectReason: reason,
      approver,
    })
  }

  function getApplication (id) {
    return applications.value.find(app => app.id === id)
  }

  function searchApplications (filters) {
    let results = [...applications.value]

    if (filters.itemCode) {
      results = results.filter(app =>
        app.itemCode?.toLowerCase().includes(filters.itemCode.toLowerCase()),
      )
    }

    if (filters.applicant) {
      results = results.filter(app =>
        app.applicant?.toLowerCase().includes(filters.applicant.toLowerCase()),
      )
    }

    if (filters.status && filters.status !== 'ALL') {
      results = results.filter(app => app.status === filters.status)
    }

    if (filters.dateFrom) {
      results = results.filter(app =>
        new Date(app.submitDate) >= new Date(filters.dateFrom),
      )
    }

    if (filters.dateTo) {
      results = results.filter(app =>
        new Date(app.submitDate) <= new Date(filters.dateTo),
      )
    }

    if (filters.category && filters.category !== 'ALL') {
      results = results.filter(app => app.mainCategory === filters.category)
    }

    return results
  }

  function exportApplications (filters) {
    return searchApplications(filters)
  }

  // 初始化
  loadApplications()
  loadCodeCounter()

  return {
    // State
    applications,
    codeCounter,
    loading,
    // Getters
    pendingApplications,
    approvedApplications,
    rejectedApplications,
    pendingCount,
    // Actions
    loadApplications,
    saveApplications,
    loadCodeCounter,
    saveCodeCounter,
    generateItemCode,
    addApplication,
    updateApplication,
    approveApplication,
    rejectApplication,
    getApplication,
    searchApplications,
    exportApplications,
  }
})
