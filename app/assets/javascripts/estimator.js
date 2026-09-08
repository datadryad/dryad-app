const feeForm = document.querySelector('form[action="/fee_estimator"]')
const journalID = document.getElementById('searchselect-journal__value')
const journalTitle = document.getElementById('searchselect-journal__label')
const output = document.getElementById('total_estimate')
const ldf = document.getElementById('ldf_info')
const setAndSubmitPayer = () => {
  output.innerHTML = '';
  ldf.innerHTML = '';
  output.appendChild(document.getElementById('calc-loading').content.cloneNode(true))
  if (feeForm.elements['institution_id'].value !== 'dryad') {
    feeForm.elements['payer_id'].value = feeForm.elements['institution_id'].value
    feeForm.elements['payer_type'].value = 'StashEngine::Tenant'
    feeForm.elements['type'].value = 'institution'
  } else if (journalID.value) {
    feeForm.elements['payer_id'].value = journalID.value;
    feeForm.elements['payer_type'].value = 'StashEngine::Journal'
    feeForm.elements['type'].value = 'publisher'
  }
  feeForm.requestSubmit()
}
feeForm.addEventListener('change', setAndSubmitPayer)
journalID.addEventListener('change', setAndSubmitPayer)
$(window).on('load', setAndSubmitPayer)
$(document).on('ajax:complete', function(status, response){
  if (response.status === 200) {
    const select = document.getElementById('institution_id')
    const {fees, limits: {limit, tier, contact}} = response.responseJSON
    const {dpc_sponsored, storage_sponsored, total} = fees
    const partner = feeForm.elements['type'].value == 'institution' ? select.options[select.selectedIndex].innerHTML : journalTitle.value
    let text = document.getElementById('unsponsored')
    if (dpc_sponsored) {
      text = document.getElementById('sponsored')
      if (total) text = document.getElementById('large-data')
    }
    const insert = text.content.cloneNode(true)
    if (insert.querySelector('.cost')) insert.querySelector('.cost').innerHTML = `${total.toLocaleString('en-US', {style: 'currency', currency: 'USD', maximumFractionDigits: 0})} USD`
    if (insert.querySelector('.org')) insert.querySelector('.org').innerHTML = partner
    if (insert.querySelector('.size')) insert.querySelector('.size').innerHTML = limit
    if (tier === 0 && storage_sponsored && insert.querySelector('.mod')) insert.querySelector('.mod').innerHTML = 'a limited amount of data over'
    output.innerHTML = ''
    output.appendChild(insert)
    if (storage_sponsored) {
      const note = document.getElementById('ldf-note').content.cloneNode(true)
      const email = document.getElementById('ldf-contact').content.cloneNode(true)
      if (contact) {
        email.querySelector('a').innerHTML = contact
        email.querySelector('a').href = `mailto:${contact}`
        note.querySelector('p').appendChild(email)
      }
      ldf.appendChild(note)
    }
  }
})