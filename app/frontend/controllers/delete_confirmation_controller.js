import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { message: String }
  
  confirm(event) {
    const message = this.messageValue || "本当に削除しますか？この操作は取り消せません。"
    
    if (!confirm(message)) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
    
    return true
  }
}