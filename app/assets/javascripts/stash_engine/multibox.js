'use strict';

class MultipleSelect {
  constructor(combobox, textbox, list) {
    this.combobox = combobox
    this.textbox = textbox
    this.list = list

    this.textbox.addEventListener('click', this.open.bind(this))

    this.textbox.addEventListener('blur', this.unFocus.bind(this), true)
    this.list.addEventListener('blur', this.unFocus.bind(this), true)
    this.combobox.addEventListener('blur', this.unFocus.bind(this), true)

    this.textbox.addEventListener('keydown', this.keyPressed.bind(this))
    this.list.addEventListener('keydown', this.listPressed.bind(this), true)

    this.list.addEventListener('click', this.selectOption.bind(this), true)
  }
  open() {
    this.list.removeAttribute('hidden')
    this.textbox.setAttribute('aria-expanded', true)
  }
  close(){
    this.list.setAttribute('hidden', true)
    this.textbox.setAttribute('aria-expanded', false)
  }
  unFocus(e) {
    if (!this.combobox.contains(e.relatedTarget)) {
      this.close()
    }
  }
  selectOption(e) {
    const checked = this.list.querySelectorAll('input[type="checkbox"]:checked')
    const selected = Array.from(checked)
    if (selected.length > 0) {
      this.textbox.value = selected.map(x => x.parentElement.textContent.trim()).join(', ')
      this.textbox.classList.add('selected')
    } else {
      this.textbox.value = ''
      this.textbox.classList.remove('selected')
    }
  }
  listPressed(e) {
    this.keyPressed(e)
  }
  keyPressed(e, option) {
    switch (e.key) {
      case 'Enter':
        if (e.target.type === 'checkbox') {
          e.preventDefault()
          e.stopPropagation()
          e.target.checked = !e.target.checked
          this.selectOption(e)
        }
        else if (e.target.id === this.textbox.id) {
          this.open()
        }
        break
      case 'ArrowDown':
      case 'ArrowRight':
        e.preventDefault()
        if (e.target.id === this.textbox.id) {
          if (this.list.hasAttribute('hidden')) this.open()
          this.list.firstElementChild.firstElementChild.focus()
        } else if (e.target.parentElement.nextElementSibling) {
          e.target.parentElement.nextElementSibling.firstElementChild.focus()
        }
        break
      case 'ArrowUp':
        e.preventDefault()
        if (e.target.id !== this.textbox.id && e.target.parentElement.previousElementSibling) {
          e.target.parentElement.previousElementSibling.firstElementChild.focus()
        }
        break
      case 'Home':
        e.preventDefault()
        if (e.target.id !== this.textbox.id) {
          this.list.firstElementChild.firstElementChild.focus()
        }
        break
      case 'End':
        e.preventDefault()
        if (e.target.id !== this.textbox.id) {
          this.list.lastElementChild.firstElementChild.focus()
        }
        break
      default:
        break
    }
  }

}
