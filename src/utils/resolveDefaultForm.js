/**
 * 解析系統預設表單 ID
 */
import { formsService } from '@/api/services/forms'

/**
 * @returns {Promise<number|string|null>}
 */
export async function resolveDefaultFormId () {
  // 1. 啟用中的預設表單
  let forms = await formsService.getForms({ is_default: true, is_active: true })
  if (forms?.length > 0) {
    return forms[0].id
  }

  // 2. 預設表單（含未啟用，優先仍啟用者）
  forms = await formsService.getForms({ is_default: true })
  if (forms?.length > 0) {
    const activeDefault = forms.find(form => form.is_active !== false)
    return (activeDefault || forms[0]).id
  }

  // 3. 向後相容：material_application
  try {
    const materialForm = await formsService.getForm('material_application', false)
    if (materialForm?.id && materialForm.is_active !== false) {
      return materialForm.id
    }
  } catch {
    // 略過
  }

  // 4. 任一啟用表單
  forms = await formsService.getForms({ is_active: true })
  if (forms?.length > 0) {
    return forms[0].id
  }

  return null
}

export const FORMS_UPDATED_EVENT = 'forms:updated'

export function notifyFormsUpdated () {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent(FORMS_UPDATED_EVENT))
  }
}
