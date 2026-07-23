import React, {useState, useEffect} from 'react';
/* eslint-disable-next-line import/no-cycle */
import Button from '../Button';

export default function ListMenu({active, editorId, ...props}) {
  const [keyed, setKeyed] = useState(false);

  const list_buttons = ['bullet_list', 'ordered_list', 'indent', 'outdent'];

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}listMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.previousElementSibling.lastElementChild.classList.add('fa-chevron-down');
    menu.previousElementSibling.lastElementChild.classList.remove('fa-chevron-up');
    menu.hidden = true;
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}listMenu`).parentElement;
    if (!element.contains(e.target)) {
      closeMenu();
      document.removeEventListener('click', clickListener);
    }
  };

  const openMenu = (e) => {
    if (e.currentTarget.getAttribute('aria-expanded') === 'true') {
      closeMenu();
    } else {
      e.currentTarget.setAttribute('aria-expanded', true);
      e.currentTarget.lastElementChild.classList.remove('fa-chevron-down');
      e.currentTarget.lastElementChild.classList.add('fa-chevron-up');
      document.getElementById(`${editorId}listMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
    if (keyed) {
      document.getElementById(`${editorId}listMenu`).firstElementChild.tabIndex = 0;
      document.getElementById(`${editorId}listMenu`).firstElementChild.focus();
    }
  };

  const leaveMenu = (e) => {
    if (e.currentTarget.contains(e.relatedTarget)) return;
    closeMenu();
  };

  const menuHandler = (ev) => {
    ev.stopPropagation();
    const next = ev.target.nextElementSibling || ev.target.parentElement.firstElementChild;
    const prev = ev.target.previousElementSibling || ev.target.parentElement.lastElementChild;
    switch (ev.key) {
    case 'ArrowRight': case 'ArrowDown':
      ev.target.tabIndex = -1;
      next.tabIndex = 0;
      next.focus();
      break;
    case 'ArrowLeft': case 'ArrowUp':
      ev.target.tabIndex = -1;
      prev.tabIndex = 0;
      prev.focus();
      break;
    case 'Home':
      ev.target.tabIndex = -1;
      ev.target.parentElement.firstElementChild.tabIndex = 0;
      ev.target.parentElement.firstElementChild.focus();
      break;
    case 'End':
      ev.target.tabIndex = -1;
      ev.target.parentElement.lastElementChild.tabIndex = 0;
      ev.target.parentElement.lastElementChild.focus();
      break;
    default:
      break;
    }
  };

  useEffect(() => {
    const menu = document.getElementById(`${editorId}listMenu`);
    if (menu) {
      menu.querySelector('*[tabindex]').tabIndex = 0;
      menu.addEventListener('keydown', menuHandler);
    }
    return () => {
      if (menu) menu.removeEventListener('keydown', menuHandler);
    };
  });

  return (
    <div className="listSelect" onBlur={leaveMenu}>
      <button
        type="button"
        className={active ? 'active' : undefined}
        title="List menu"
        aria-label="List menu"
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={`${editorId}listMenu`}
        tabIndex="-1"
        onClick={openMenu}
        onKeyDown={(e) => { if (['Space', 'Enter'].includes(e.key)) setKeyed(true); }}
      >
        <i className="fas fa-bars" aria-hidden="true" />
        <i className="fas fa-chevron-down" aria-hidden="true" />
      </button>
      <div className="listMenu" role="menu" id={`${editorId}listMenu`} hidden>
        {list_buttons.map((b) => (
          <Button key={b} type={b} editorId={editorId} {...props} />
        ))}
      </div>
    </div>
  );
}
