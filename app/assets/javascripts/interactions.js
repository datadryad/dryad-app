function preventClicks(e) {
  const button = e.currentTarget;
  const icon = button.querySelector('i');
  if (button.form) {
    button.form.addEventListener('submit', () => {
      icon.className = 'fas fa-circle-notch fa-spin';
      document.body.classList.add('prevent-clicks');
      button.disabled = true;
    })
  } else {
    icon.className = 'fas fa-circle-notch fa-spin';
    document.body.classList.add('prevent-clicks');
    button.disabled = true;
  }
}

function copyItem(e) {
  const item = e.currentTarget.dataset.item
  const icon = e.currentTarget.firstElementChild
  const citation = e.currentTarget.nextElementSibling.innerText
  window.navigator.clipboard.writeText(citation).then(() => {
    icon.classList.remove('fa-paste');
    icon.classList.add('fa-check');
    icon.innerHTML = `<span class="screen-reader-only">${item} copied</span>`
    setTimeout(function(){
      icon.parentElement.setAttribute('title', `Copy ${item.toLowerCase()}`);
      icon.classList.add('fa-paste');
      icon.classList.remove('fa-check');
      icon.innerHTML = '';
    }, 2000);
  });
}
document.querySelectorAll('.copy-icon').forEach((button) => {
  button.addEventListener('click', copyItem)
  button.addEventListener('keydown', (e) => {
    if (event.key === ' ' || event.key === 'Enter') {
      copyItem(e)
    }
  });
});

function copyEmail(e) {
  const copyButton = e.currentTarget.firstElementChild;
  const email = e.currentTarget.previousSibling.textContent.split('').reverse().join('');
  navigator.clipboard.writeText(email).then(() => {
    // Successful copy
    copyButton.parentElement.setAttribute('title', 'Email copied');
    copyButton.classList.remove('fa-paste');
    copyButton.classList.add('fa-check');
    copyButton.innerHTML = '<span class="screen-reader-only">Email address copied</span>'
    setTimeout(function(){
      copyButton.parentElement.setAttribute('title', 'Copy email');
      copyButton.classList.add('fa-paste');
      copyButton.classList.remove('fa-check');
      copyButton.innerHTML = '';
    }, 2000);
  });
}

var emails = document.getElementsByClassName('emailr');
for (var i=0; i < emails.length; i++) {
  const element = emails[i];
  element.addEventListener('click', (e) => {
    var mailto = e.currentTarget.href
    var email = e.currentTarget.textContent.split('').reverse().join('');
    e.currentTarget.href = mailto.replace('dev@null', email);
  });
  const newEl = document.createElement("span");
  newEl.setAttribute('class', 'nobr');
  const cb = document.createElement("span");
  cb.setAttribute('class', 'copy-icon');
  cb.setAttribute('role', 'button');
  cb.setAttribute('tabindex', 0);
  cb.setAttribute('aria-label', `Copy address to ${element.getAttribute('aria-label').replace(/^\p{Lu}/u, char => char.toLocaleLowerCase('en-US'))}`);
  cb.setAttribute('title', 'Copy email');
  cb.innerHTML = '<i class="fa fa-paste" role="status"></i>';
  element.parentNode.insertBefore(newEl, element);
  newEl.appendChild(element)
  newEl.appendChild(cb)
  cb.addEventListener('click', copyEmail)
  cb.addEventListener('keydown', (e) => {
    if (event.key === ' ' || event.key === 'Enter') {
      copyEmail(e)
    }
  });
};

function localize(time) {
  const date = new Date(time);
  return date.toLocaleString('en-US', {month: 'short', day: 'numeric', year: 'numeric', hour: 'numeric', minute: 'numeric'}).replace(/ ([AP][M])/, '\xa0$1');
}
[...document.querySelectorAll('.local-date')].forEach((span) => {
  if (span.dataset.dt) span.innerText = localize(span.dataset.dt);
});

const timezone = document.getElementById('timezone');
if (timezone) {
  const date = new Date();
  timezone.innerText = date.toLocaleString('en-US', {day: '2-digit', timeZoneName: 'longGeneric'}).substring(4);
} 

var navButtons = Array.from(document.getElementsByClassName('c-header_nav-button'));
navButtons.forEach(button => {
  button.parentElement.addEventListener('mouseenter', (e) => {
    if (window.innerWidth > 899) {
      const closed = button.getAttribute('aria-expanded') === 'false';
      navButtons.forEach(nb => {
        nb.setAttribute('aria-expanded', 'false');
        nb.parentElement.classList.remove('is-open');
        nb.nextElementSibling.setAttribute('hidden', true);
      });
      if (closed) {
        button.parentElement.classList.add('is-open');
        button.setAttribute('aria-expanded', 'true');
        button.nextElementSibling.removeAttribute('hidden');
      }
    }
  })
  button.parentElement.addEventListener('mouseleave', (e) => {
    if (window.innerWidth > 899) {
      navButtons.forEach(nb => {
        nb.setAttribute('aria-expanded', 'false');
        nb.parentElement.classList.remove('is-open');
        nb.nextElementSibling.setAttribute('hidden', true);
      });
    }
  })
  button.parentElement.addEventListener('focusout', (e) => {
    if (button.parentElement.contains(e.relatedTarget)) return
    if (window.innerWidth > 899) {
      navButtons.forEach(nb => {
        nb.setAttribute('aria-expanded', 'false');
        nb.parentElement.classList.remove('is-open');
        nb.nextElementSibling.setAttribute('hidden', true);
      });
    }
  })
  button.addEventListener('click', (e) => {
    const closed = button.getAttribute('aria-expanded') === 'false';
    navButtons.forEach(nb => {
      nb.setAttribute('aria-expanded', 'false');
      nb.parentElement.classList.remove('is-open');
      nb.nextElementSibling.setAttribute('hidden', true);
    });
    if (closed) {
      button.parentElement.classList.add('is-open');
      button.setAttribute('aria-expanded', 'true');
      button.nextElementSibling.removeAttribute('hidden');
    }
  })
});

function expandButtonMenu(e) {
  const closed = e.currentTarget.getAttribute('aria-expanded') === 'false';
  const section = document.getElementById(e.currentTarget.getAttribute('aria-controls'))
  const baseURL = window.location.pathname + window.location.search
  if (closed) {
    const newHash = '#' + e.currentTarget.id
    history.replaceState('', '', baseURL + newHash);
    e.currentTarget.setAttribute('aria-expanded', 'true');
    section.removeAttribute('hidden');
  } else {
    history.replaceState('', '', baseURL);
    e.currentTarget.setAttribute('aria-expanded', 'false');
    section.setAttribute('hidden', true);
  }
}
var expandButtons = Array.from(document.querySelectorAll('.expand-button button'));
expandButtons.forEach(button => {
  button.addEventListener('click', expandButtonMenu)
  button.addEventListener('keydown', (e) => {
    if (e.key === ' ' || e.key === 'Enter') {
      e.preventDefault()
      expandButtonMenu(e)
    }
  });
});

if (window.location.hash) {
  const hashed = document.getElementById(window.location.hash.substring(1))
  if (hashed && hashed.getAttribute('aria-expanded') === 'false') {
    hashed.setAttribute('aria-expanded', 'true');
    const section = document.getElementById(hashed.getAttribute('aria-controls'))
    section.removeAttribute('hidden');
  }
}

if (!!document.getElementById('nav-mobile-buttons')) {
  const leftButton = document.getElementById('left-scroll-button');
  const rightButton = document.getElementById('right-scroll-button');
  const menu = document.getElementById('nav-mobile-buttons').previousElementSibling
  let menuSize = 0
  $('#page-nav a').each(function(){
    menuSize += $(this).outerWidth()
  })
  let menuAverage = menuSize/$('#page-nav a').length
  let menuWrapperSize = $(menu).outerWidth();
  let menuInvisibleSize = menuSize - menuWrapperSize;
  let menuPosition = menu.scrollLeft;
  let menuEndOffset = menuInvisibleSize - 22;

  const checkButtons = function() {
    if (menuInvisibleSize < 0) {
      leftButton.setAttribute('hidden', true)
      rightButton.setAttribute('hidden', true)
    } else if (menuPosition <= 22) {
      leftButton.setAttribute('hidden', true)
      rightButton.removeAttribute('hidden')
    } else if (menuPosition < menuEndOffset) {
      leftButton.removeAttribute('hidden')
      rightButton.removeAttribute('hidden')
    } else if (menuPosition >= menuEndOffset) {
      rightButton.setAttribute('hidden', true)
      leftButton.removeAttribute('hidden')
    }
  }

  checkButtons();
  
  $(window).on('resize', function() {
    menuWrapperSize = $(menu).outerWidth();
    menuInvisibleSize = menuSize - menuWrapperSize;
    menuPosition = menu.scrollLeft;
    menuEndOffset = menuInvisibleSize - 22;
    checkButtons();
  });   

  $(menu).on('scroll', function() {
    menuInvisibleSize = menuSize - menuWrapperSize;
    menuPosition = menu.scrollLeft;
    menuEndOffset = menuInvisibleSize - 22;
    checkButtons();
  });

  var scrollDuration = 150;
  // scroll to left
  $(rightButton).on('click', function() {
    $(menu).animate( { scrollLeft: menuPosition += (menuAverage + 22)}, scrollDuration);
  });

  // scroll to right
  $(leftButton).on('click', function() {
    $(menu).animate( { scrollLeft: menuPosition -= (menuAverage + 22) }, scrollDuration);
  });
}