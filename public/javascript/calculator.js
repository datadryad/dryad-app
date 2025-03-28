const ranges = document.querySelectorAll('input[type=range]')
ranges.forEach(r => {
  r.addEventListener('change', () => {
    r.nextElementSibling.value = r.value
    const max = 100 - parseInt(r.value)
    const taken = Array.from(ranges).reduce((t, ra) => ra.id !== r.id ? t += parseInt(ra.value) : t, 0)
    const set = Array.from(ranges).reduce((s, ra) => {
      if (ra.id !== r.id && parseInt(ra.value) > 0) s.push(ra)
      return s
    }, []).sort((a, b) => parseInt(b.value) - parseInt(a.value));
    if (taken > max) {
      let subt = taken - max;
      set.forEach(or => {
        if (subt > 0) {
          let newVal = Math.round(parseInt(or.value) - subt);
          if (newVal < 0) newVal = 0;
          subt = subt - Math.round(parseInt(or.value));
          or.value = newVal;
          or.nextElementSibling.value = newVal;
        }
      })
    }
  })
})
$(document).on("ajax:complete", function(status, response){
  if (response.status === 200) {
    const {fees: {total}} = response.responseJSON;
    document.getElementById('total_estimate').innerHTML = total;
  }
})