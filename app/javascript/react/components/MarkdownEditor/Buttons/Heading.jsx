import React, {useState, useEffect} from 'react';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {commands} from '../milkdownCommands';
import {commands as mdCommands} from '../codeKeymap';
import {labels} from './Details';

/* eslint-disable jsx-a11y/no-noninteractive-element-to-interactive-role */

export default function Heading({
  active, editor, editorId, mdEditor, activeEditor, headingLevel,
}) {
  const [selectedLevel, setSelectedLevel] = useState(headingLevel);
  const [keyed, setKeyed] = useState(false);
  const levels = [1, 2, 3, 4, 5, 6, 0];

  const text = (level) => (level === 0 && 'Normal text') || (level === 1 && 'Title') || `Heading ${level}`;

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}headingMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.previousElementSibling.lastElementChild.classList.add('fa-chevron-down');
    menu.previousElementSibling.lastElementChild.classList.remove('fa-chevron-up');
    menu.hidden = true;
  };

  const onChange = (newSelectedLevel) => {
    setSelectedLevel(newSelectedLevel);
    if (activeEditor === 'visual') {
      editor()?.action(callCommand(commands.heading.key, newSelectedLevel));
      const view = editor()?.ctx.get(editorViewCtx);
      view.focus();
    } else if (activeEditor === 'markdown') {
      mdCommands[`heading${newSelectedLevel}`](mdEditor);
      mdEditor.focus();
    }
    const button = document.getElementById(`${editorId}headingButton`);
    if (newSelectedLevel > 0) {
      button.setAttribute('aria-pressed', true);
      button.classList.add('active');
    } else {
      button.setAttribute('aria-pressed', false);
      button.classList.remove('active');
    }
    closeMenu();
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}headingMenu`).parentElement;
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
      document.getElementById(`${editorId}headingMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
    if (keyed) {
      document.getElementById(`${editorId}headingMenu`).querySelector('.selected').focus();
    }
  };

  const menuHandler = (ev) => {
    ev.stopPropagation();
    const next = ev.target.nextElementSibling || ev.target.parentElement.firstElementChild;
    const prev = ev.target.previousElementSibling || ev.target.parentElement.lastElementChild;
    switch (ev.key) {
    case 'Space': case 'Enter':
      ev.preventDefault();
      onChange(ev.target.dataset.level);
      break;
    case 'ArrowRight': case 'ArrowDown':
      next.focus();
      break;
    case 'ArrowLeft': case 'ArrowUp':
      prev.focus();
      break;
    case 'Home':
      ev.target.parentElement.firstElementChild.focus();
      break;
    case 'End':
      ev.target.parentElement.lastElementChild.focus();
      break;
    default:
      break;
    }
  };

  useEffect(() => {
    const menu = document.getElementById(`${editorId}headingMenu`);
    if (menu) {
      menu.querySelector('*[tabindex]').tabIndex = 0;
      menu.addEventListener('keydown', menuHandler);
    }
    return () => {
      if (menu) menu.removeEventListener('keydown', menuHandler);
    };
  });

  useEffect(() => {
    setSelectedLevel(headingLevel);
  }, [headingLevel]);

  return (
    <div className="headingSelect">
      <button
        type="button"
        className={`headingButton${active ? ' active' : ''}`}
        id={`${editorId}headingButton`}
        aria-pressed={active}
        aria-label={labels.heading}
        title={labels.heading}
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={`${editorId}headingMenu`}
        tabIndex="-1"
        onClick={openMenu}
        onKeyDown={(e) => { if (['Space', 'Enter'].includes(e.key)) setKeyed(true); }}
      >
        <span>{text(selectedLevel)}</span>
        <i className="fas fa-chevron-down" aria-hidden="true" />
      </button>
      <ul hidden role="menu" id={`${editorId}headingMenu`} aria-label="Heading levels" className="headingMenu">
        {levels.map((level) => (
          <li
            role="menuitemradio"
            tabIndex="-1"
            className={`h${level} ${Number(selectedLevel) === level ? 'selected' : ''}`}
            aria-checked={Number(selectedLevel) === level}
            key={`heading${level}`}
            onClick={() => onChange(level)}
            onKeyDown={() => true}
            data-level={level}
          >
            {text(level)}
          </li>
        ))}
      </ul>
    </div>
  );
}
