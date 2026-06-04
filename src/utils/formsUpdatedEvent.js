/** 表單定義更新後通知各頁面重新載入 */
export const FORMS_UPDATED_EVENT = 'forms:updated'

export function notifyFormsUpdated () {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent(FORMS_UPDATED_EVENT))
  }
}
