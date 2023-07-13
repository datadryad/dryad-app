// ##### Main JavaScript ##### //

function joelsReady(){

  // ***** Upload Modal Component ***** //

  if (document.querySelector('.js-uploadmodal__button-show-modal')) {
    var buttonShowModal = document.querySelectorAll('.js-uploadmodal__button-show-modal');
    var buttonCloseModal = document.querySelectorAll('.js-uploadmodal__button-close-modal');

    buttonShowModal.forEach(function(button) {
      button.addEventListener('click', function() {
        uploadModal.showModal();
      });
    });

    buttonCloseModal.forEach(function(button) {
      button.addEventListener('click', function() {
        uploadModal.close();
      });
    });
  }

  // ***** Select Content Object ***** //

  $('.o-select__select').change(function(){
    $(this).find('option:selected').each(function(){
      if($(this).hasClass('js-select__option1')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content1').show();
      }
      else if($(this).hasClass('js-select__option2')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content2').show();
      }
      else if($(this).hasClass('js-select__option3')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content3').show();
      }
      else if($(this).hasClass('js-select__option4')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content4').show();
      }
      else if($(this).hasClass('js-select__option5')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content5').show();
      }
      else if($(this).hasClass('js-select__option6')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content6').show();
      }
      else if($(this).hasClass('js-select__option7')){
        $(this).parents('.o-select__input').siblings('.o-select__content').not().hide();
        $(this).parents('.o-select__input').siblings('.js-select__content7').show();
      }
      else{
        $(this).parents('.o-select__input').siblings('.o-select__content').hide();
      }
    });
  }).change();

  // ***** Location Inputs ***** //

  $('.js-location__box-inputs').hide();

  $('.js-location__point-button').click(function(){
    $('.js-location__point-inputs').show();
    $('.js-location__box-inputs').hide();
    $('.js-location__point-button').removeClass('c-location__point-button');
    $('.js-location__point-button').addClass('c-location__point-button--active');
    $('.js-location__box-button').removeClass('c-location__box-button--active');
    $('.js-location__box-button').addClass('c-location__box-button');
  });

  $('.js-location__box-button').click(function(){
    $('.js-location__box-inputs').show();
    $('.js-location__point-inputs').hide();
    $('.js-location__box-button').removeClass('c-location__box-button');
    $('.js-location__box-button').addClass('c-location__box-button--active');
    $('.js-location__point-button').removeClass('c-location__point-button--active');
    $('.js-location__point-button').addClass('c-location__point-button');
  });

  // ***** Facets ***** //

  $('.js-facet__deselect-button').click(function(){
    $(this).parent().siblings().children('.js-facet__check-input').prop('checked', false);
    $(this).attr('disabled', '');
  });

  $('.js-facet__check-input').click(function() {
    if ($(this).is(':checked')) {
      $(this).parent().siblings().find('.js-facet__deselect-button').removeAttr('disabled');
    } else {
      $(this).parent().siblings().find('.js-facet__deselect-button').attr('disabled', '');
    }
    
  });

  $('.js-facet__toggle-button').click(function(){
    $(this).toggleClass('c-facet__toggle-button--open c-facet__toggle-button');
    $(this).parents().siblings('.js-facet__check-group').toggleClass('c-facet__check-group--open c-facet__check-group');
    $(this).parent().siblings('.js-facet__deselect-button').toggleClass('c-facet__deselect-button--open c-facet__deselect-button');
  });

  // ***** Alert Close ***** //

  $('.js-alert__close').click(function(){
    $(this).parent('.js-alert').fadeToggle();
  });

  // ***** Header Mobile Menu Toggle ***** //

  $('#header-menu-button').click(function(){
    $(this).attr('aria-expanded', (i, attr) => {
      return attr == 'true' ? 'false' : 'true';
    });
    $(this).parent().toggleClass('is-open');
    $('#site-menu').toggleClass('is-open');
  });

  // ***** Required Field State ***** //

  $('[required]').map(function() {
    $(this).siblings('label').removeClass('c-input__label');
    $(this).siblings('label').addClass('c-input__label--required');
  });

  // ***** Publication Dates ***** //

  $('.js-pubdate__release-date-input').attr('value', 'mm/dd/yyyy');

  var week1 = moment().add(1, 'week').format('M/DD/YYYY');
  var week1datetime = moment().add(1, 'week').format('YYYY-MM-DD');
  $('.js-pubdate__week1').text(week1);
  $('.js-pubdate__week1').attr('datetime', week1datetime);

  var month1 = moment().add(1, 'month').format('M/DD/YYYY');
  var month1datetime = moment().add(1, 'month').format('YYYY-MM-DD');
  $('.js-pubdate__month1').text(month1);
  $('.js-pubdate__month1').attr('datetime', month1datetime);

  var month3 = moment().add(3, 'month').format('M/DD/YYYY');
  var month3datetime = moment().add(3, 'month').format('YYYY-MM-DD');
  $('.js-pubdate__month3').text(month3);
  $('.js-pubdate__month3').attr('datetime', month3datetime);

  var month6 = moment().add(6, 'month').format('M/DD/YYYY');
  var month6datetime = moment().add(6, 'month').format('YYYY-MM-DD');
  $('.js-pubdate__month6').text(month6);
  $('.js-pubdate__month6').attr('datetime', month6datetime);

  var year1 = moment().add(1, 'year').format('M/DD/YYYY');
  var year1datetime = moment().add(1, 'year').format('YYYY-MM-DD');
  $('.js-pubdate__year1').text(year1);
  $('.js-pubdate__year1').attr('datetime', year1datetime);

  var emails = document.getElementsByClassName('emailr');
  for (var i=0; i < emails.length; i++) {
    emails[i].onclick = e => {
      var email = e.currentTarget.textContent.split('').reverse().join('');
      e.currentTarget.href='mailto:'+email;
    }

    const newEl = document.createElement("span");
    newEl.setAttribute('class', 'copy-icon');
    newEl.innerHTML = '&nbsp;<i class="fa fa-clipboard" aria-hidden="true"><i><span style="display: none">&nbsp;copied</span>';
    const element = emails[i];
    element.parentNode.insertBefore(newEl, element.nextSibling);
    newEl.onclick = e => {
      e.preventDefault();
      const copyText = e.currentTarget.getElementsByTagName('span')[0];
      const email = e.currentTarget.previousSibling.textContent.split('').reverse().join('');
      navigator.clipboard.writeText(email).then(() => {
        // Successful copy
        copyText.style.display = 'inline';
        setTimeout(function(){
          copyText.style.display = 'none';
        }, 2000);
      });
    }
  };

  var navButtons = Array.from(document.getElementsByClassName('c-header_nav-button'));
  navButtons.forEach(button => {
    button.onclick = e => {
      const closed = e.currentTarget.getAttribute('aria-expanded') === 'false';
      navButtons.forEach(nb => {
        nb.setAttribute('aria-expanded', 'false');
        nb.parentElement.classList.remove('is-open');
        nb.nextElementSibling.setAttribute('hidden', true);
      });
      if (closed) {
        e.currentTarget.parentElement.classList.add('is-open');
        e.currentTarget.setAttribute('aria-expanded', 'true');
        e.currentTarget.nextElementSibling.removeAttribute('hidden');
      }
    }
  });

  var expandButtons = Array.from(document.getElementsByClassName('expand-button'));
  expandButtons.forEach(button => {
    button.onclick = e => {
      const closed = e.currentTarget.getAttribute('aria-expanded') === 'false';
      const baseURL = window.location.pathname + window.location.search
      if (closed) {
        const newHash = '#' + e.currentTarget.id
        history.replaceState('', '', baseURL + newHash);
        e.currentTarget.setAttribute('aria-expanded', 'true');
        e.currentTarget.nextElementSibling.removeAttribute('hidden');
      } else {
        history.replaceState('', '', baseURL);
        e.currentTarget.setAttribute('aria-expanded', 'false');
        e.currentTarget.nextElementSibling.setAttribute('hidden', true);
      }
    }
  });

  if (window.location.hash) {
    const hashed = document.getElementById(window.location.hash.substring(1))
    if (hashed.getAttribute('aria-expanded') === 'false') {
      hashed.setAttribute('aria-expanded', 'true');
      hashed.nextElementSibling.removeAttribute('hidden');
    }
  }

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
        div.innerHTML = `<p class="blog-post-heading" role="heading" aria-level="3">${title}</p><p>${desc}</p>`
        sec.appendChild(div)
        return i < limit
      })
    })
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

}// close joelsReady()
