// see http://stackoverflow.com/questions/6214201/best-practices-for-loading-page-content-via-ajax-request-in-rails3
// for information about how data-load works, only I made it more standard UJS.
const load_data = function() {
  $("[data-load]:not([data-loaded])").filter((i, el) => el.checkVisibility()).each(function () {
    var path = $(this).attr('data-load');
    // $(this).load(path);
    $.ajax({
      method: 'GET',
      url: path,
      dataType: 'script',
      async: true,
      cache: false,
    });
    $(this).attr('data-loaded')
  });
}

$(window).on("load", load_data);

if (!!document.getElementById('blog-latest-posts')) {
  const sec = document.getElementById('blog-latest-posts')
  const url = sec.dataset.feed || 'https://blog.datadryad.org/feed'
  const limit = sec.dataset.count - 1
  $.get(url, (data) => {
    sec.innerHTML = ''
    $(data).find('item').each((i, post) => {
      const title = post.querySelector('title').innerHTML
      const link = post.querySelector('link').innerHTML
      const desc = $(post.querySelector('description')).text()
      const div = document.createElement('div')
      div.classList.add('latest-post')
      div.innerHTML = `<p class="blog-post-heading" role="heading" aria-level="3"><a href="${link}">${title}</a></p>${desc}`
      div.removeChild(div.lastElementChild)
      sec.appendChild(div)
      return i < limit
    })
  })
}     

const details = document.getElementsByClassName('c-file-group')
for (const expander of details) {
  expander.addEventListener('toggle', (e) => {
    load_data()
  })
}