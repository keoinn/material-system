/**
 * SweetAlert2 Composable
 * 統一的提示框工具
 */
import Swal from 'sweetalert2'

// 統一的按鈕樣式配置
const buttonStyle = {
  buttonsStyling: true,
  customClass: {
    confirmButton: 'swal2-confirm-custom',
    cancelButton: 'swal2-cancel-custom',
  },
}

export function useSwal () {
  /**
   * 成功提示
   */
  const success = (message, title = '成功') => {
    return Swal.fire({
      icon: 'success',
      title,
      text: message,
      confirmButtonText: '確定',
      confirmButtonColor: '#667eea',
      ...buttonStyle,
    })
  }

  /**
   * 錯誤提示
   */
  const error = (message, title = '錯誤') => {
    return Swal.fire({
      icon: 'error',
      title,
      text: message,
      confirmButtonText: '確定',
      confirmButtonColor: '#dc3545',
      ...buttonStyle,
    })
  }

  /**
   * 警告提示
   */
  const warning = (message, title = '警告') => {
    return Swal.fire({
      icon: 'warning',
      title,
      text: message,
      confirmButtonText: '確定',
      confirmButtonColor: '#ffc107',
      ...buttonStyle,
    })
  }

  /**
   * 資訊提示
   */
  const info = (message, title = '提示') => {
    return Swal.fire({
      icon: 'info',
      title,
      text: message,
      confirmButtonText: '確定',
      confirmButtonColor: '#17a2b8',
      ...buttonStyle,
    })
  }

  /**
   * 確認對話框
   */
  const confirm = (message, title = '確認') => {
    return Swal.fire({
      icon: 'question',
      title,
      text: message,
      showCancelButton: true,
      confirmButtonText: '確定',
      cancelButtonText: '取消',
      confirmButtonColor: '#667eea',
      cancelButtonColor: '#6c757d',
      ...buttonStyle,
    })
  }

  /**
   * 輸入對話框
   */
  const prompt = (message, title = '輸入', inputType = 'text', inputValue = '') => {
    return Swal.fire({
      icon: 'question',
      title,
      text: message,
      input: inputType,
      inputValue,
      showCancelButton: true,
      confirmButtonText: '確定',
      cancelButtonText: '取消',
      confirmButtonColor: '#667eea',
      cancelButtonColor: '#6c757d',
      ...buttonStyle,
      inputValidator: value => {
        if (!value) {
          return '請輸入內容'
        }
      },
    })
  }

  return {
    success,
    error,
    warning,
    info,
    confirm,
    prompt,
  }
}
