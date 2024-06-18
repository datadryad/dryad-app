'use strict';

class ComboboxAutocomplete {
  constructor(combobox, textbox, list, fill, selection) {
    this.combobox = combobox
    this.textbox = textbox
    this.list = list
    this.fill = fill
    this.selection = selection

    this.textbox.addEventListener('beforeinput', this.open.bind(this))
    this.textbox.addEventListener('input', this.enter.bind(this))

    this.textbox.addEventListener('blur', this.unFocus.bind(this), true)
    this.list.addEventListener('blur', this.unFocus.bind(this), true)
    this.combobox.addEventListener('blur', this.unFocus.bind(this), true)

    this.textbox.addEventListener('keydown', this.keyPressed.bind(this))
    this.list.addEventListener('keydown', this.listPressed.bind(this), true)

    this.list.addEventListener('click', this.saveOption.bind(this), true)
  }
  open() {
    this.fill()
    this.list.removeAttribute('hidden')
    this.textbox.setAttribute('aria-expanded', true)
  }
  enter() {
    this.fill()
    if (this.textbox.value.length == 0) {
      this.selection({value: '', label: ''})
    }
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
  selectOption({value, label}) {
    const [prev] = this.list.getElementsByClassName('selected-option')
    if (prev) {
      prev.classList.remove('selected-option')
      prev.setAttribute('aria-selected', false)
    }
    const selected = this.list.querySelector(`[data-value="${value}"]`)
    selected.classList.add('selected-option')
    selected.setAttribute('aria-selected', true)
    this.selection({value, label})
    this.textbox.value = label
  }
  saveOption(e) {
    e.preventDefault()
    e.stopPropagation()
    this.selectOption(e.target.dataset)    
    this.textbox.focus()
    this.close()
  }
  listPressed(e) {
    this.keyPressed(e)
  }
  keyPressed(e, option) {
    switch (e.key) {
      case 'Enter':
        if (e.target.hasAttribute('data-value')) this.saveOption(e)
        else if (e.target.id === this.textbox.id) {
          this.open()
          e.preventDefault()
        }
        break
      case 'ArrowDown':
      case 'ArrowRight':
        if (e.target.id === this.textbox.id) {
          if (this.list.hasAttribute('hidden')) this.open()
          this.list.firstChild.focus()
          e.preventDefault()
        } else if (e.target.nextSibling) {
          e.target.nextSibling.focus()
          e.preventDefault()
        }
        break
      case 'ArrowUp':
        if (e.target.id !== this.textbox.id && e.target.previousSibling) {
          e.target.previousSibling.focus()
          e.preventDefault()
        }
        break
      case 'Home':
        if (e.target.id !== this.textbox.id) {
          this.list.firstChild.focus()
          e.preventDefault()
        }
        break
      case 'End':
        if (e.target.id !== this.textbox.id) {
          this.list.lastChild.focus()
          e.preventDefault()
        }
        break
      default:
        break
    }
  }

}
