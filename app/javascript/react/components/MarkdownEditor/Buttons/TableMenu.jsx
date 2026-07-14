import React, {useState, useEffect} from 'react';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {
  selectRowCommand,
  selectColCommand,
  moveRowCommand,
  moveColCommand,
  addColBeforeCommand,
  addColAfterCommand,
  addRowBeforeCommand,
  addRowAfterCommand,
  deleteSelectedCellsCommand,
} from '@milkdown/kit/preset/gfm';

const nodeIndex = (parent, child) => {
  /* eslint-disable-next-line no-plusplus */
  for (let i = 0; i < parent.childCount; ++i) {
    if (parent.child(i) === child) return i;
  }
  return -1;
};

const rowIcon = <i className="fas fa-table-cells-large fa-rotate-270 one" />;
const colIcon = <i className="fas fa-table-cells-large one" />;

export default function TableMenu({active, editor, editorId}) {
  const [keyed, setKeyed] = useState(false);
  const [col, setCol] = useState(null);
  const [row, setRow] = useState(null);
  const [rowCount, setRowCount] = useState(null);
  const [colCount, setColCount] = useState(null);

  const getIndexes = () => {
    if (editor) {
      const view = editor()?.ctx.get(editorViewCtx);
      const {doc, selection: {from}} = view.state;
      const $pos = doc.resolve(from);
      const {path} = $pos;
      const table = path.find((n) => n.type?.name === 'table');
      const r = path.find((n) => ['table_row', 'table_header_row'].includes(n.type?.name));
      const c = path.find((n) => ['table_cell', 'table_header'].includes(n.type?.name));
      setRowCount(table.childCount);
      setColCount(r.childCount);
      setRow(nodeIndex(table, r));
      setCol(nodeIndex(r, c));
    }
  };

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}tableOptMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.previousElementSibling.lastElementChild.classList.add('fa-chevron-down');
    menu.previousElementSibling.lastElementChild.classList.remove('fa-chevron-up');
    menu.hidden = true;
    setKeyed(false);
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}tableOptMenu`).parentElement;
    if (!element.contains(e.target)) {
      closeMenu();
      document.removeEventListener('click', clickListener);
    }
  };

  const openMenu = (e) => {
    if (e.currentTarget.hasAttribute('aria-disabled')) return;
    if (e.currentTarget.getAttribute('aria-expanded') === 'true') {
      closeMenu();
    } else {
      getIndexes();
      e.currentTarget.setAttribute('aria-expanded', true);
      e.currentTarget.lastElementChild.classList.remove('fa-chevron-down');
      e.currentTarget.lastElementChild.classList.add('fa-chevron-up');
      document.getElementById(`${editorId}tableOptMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
    if (keyed) {
      document.getElementById(`${editorId}tableOptMenu`).firstElementChild.firstElementChild.tabIndex = 0;
      document.getElementById(`${editorId}tableOptMenu`).firstElementChild.firstElementChild.focus();
    }
  };

  const subMenuExit = (button) => {
    const menu = document.getElementById(button.getAttribute('aria-controls'));
    button.setAttribute('aria-expanded', false);
    [...menu.children].forEach((li) => { li.firstElementChild.tabIndex = -1; });
    menu.hidden = true;
  };

  const subMenuOpen = (e) => {
    document.querySelectorAll('.tableSubMenu').forEach((b) => subMenuExit(b));
    const menu = document.getElementById(e.target.getAttribute('aria-controls'));
    e.target.setAttribute('aria-expanded', true);
    if (menu) menu.removeAttribute('hidden');
  };

  const leaveMenu = (e) => {
    if (e.currentTarget.contains(e.relatedTarget)) return;
    document.querySelectorAll('.tableSubMenu').forEach((b) => subMenuExit(b));
    closeMenu();
  };

  const callEditorCommand = (e, command, variables) => {
    if (e.currentTarget.hasAttribute('aria-disabled')) return;
    editor()?.action(callCommand(command.key, variables));
    const view = editor()?.ctx.get(editorViewCtx);
    view.focus();
  };

  const menuHandler = (ev) => {
    ev.stopPropagation();
    const item = ev.target.parentElement;
    const next = item.nextElementSibling?.firstElementChild || item.parentElement.firstElementChild.firstElementChild;
    const prev = item.previousElementSibling?.firstElementChild || item.parentElement.lastElementChild.firstElementChild;
    switch (ev.key) {
    case 'ArrowRight':
      if (ev.target.classList.contains('tableSubMenu')) {
        const menu = document.getElementById(ev.target.getAttribute('aria-controls'));
        subMenuOpen(ev);
        menu.firstElementChild.firstElementChild.tabIndex = 0;
        menu.firstElementChild.firstElementChild.focus();
      }
      break;
    case 'ArrowLeft':
      if (ev.target.classList.contains('tableSubMenu')) subMenuExit(ev.target);
      else if (item.parentElement.getAttribute('role') === 'menu') {
        subMenuExit(document.getElementById(`${item.parentElement.id}B`));
        document.getElementById(`${item.parentElement.id}B`).tabIndex = 0;
        document.getElementById(`${item.parentElement.id}B`).focus();
      }
      break;
    case 'ArrowDown':
      ev.target.tabIndex = -1;
      next.tabIndex = 0;
      next.focus();
      break;
    case 'ArrowUp':
      ev.target.tabIndex = -1;
      prev.tabIndex = 0;
      prev.focus();
      break;
    case 'Home':
      ev.target.tabIndex = -1;
      item.parentElement.firstElementChild.firstElementChild.tabIndex = 0;
      item.parentElement.firstElementChild.firstElementChild.focus();
      break;
    case 'End':
      ev.target.tabIndex = -1;
      item.parentElement.lastElementChild.firstElementChild.tabIndex = 0;
      item.parentElement.lastElementChild.firstElementChild.focus();
      break;
    default:
      break;
    }
  };

  useEffect(() => {
    const menu = document.getElementById(`${editorId}tableOptMenu`);
    if (menu) {
      menu.querySelector('*[tabindex]').tabIndex = 0;
      menu.addEventListener('keydown', menuHandler);
    }
    return () => {
      if (menu) menu.removeEventListener('keydown', menuHandler);
    };
  });

  return (
    <div className="tableSelect" onBlur={leaveMenu}>
      <button
        type="button"
        className="tableOptButton"
        title="Table menu"
        aria-label="Table menu"
        aria-expanded="false"
        aria-controls={`${editorId}tableOptMenu`}
        aria-haspopup="true"
        onClick={openMenu}
        onKeyDown={(e) => { if (['Space', 'Enter'].includes(e.key)) setKeyed(true); }}
        aria-disabled={!active || null}
        tabIndex="-1"
      >
        <i className="fas fa-table-cells-large" aria-hidden="true" />
        <i className="fas fa-chevron-down" aria-hidden="true" />
      </button>
      <ul className="tableOptMenu" id={`${editorId}tableOptMenu`} hidden role="menu">
        <li onMouseLeave={() => subMenuExit(document.getElementById(`${editorId}rowMenuB`))} role="presentation">
          <button
            type="button"
            role="menuitem"
            tabIndex="-1"
            className="tableSubMenu"
            id={`${editorId}rowMenuB`}
            aria-controls={`${editorId}rowMenu`}
            aria-expanded="false"
            aria-haspopup="true"
            onMouseEnter={subMenuOpen}
          ><i className="fas fa-table-columns fa-rotate-270" aria-hidden="true" />Rows<i className="fas fa-chevron-right" aria-hidden="true" />
          </button>
          <ul hidden id={`${editorId}rowMenu`} role="menu">
            <li role="presentation">
              <button type="button" role="menuitem" tabIndex="-1" onClick={(e) => callEditorCommand(e, addRowBeforeCommand)}>
                <span className="icon-stack">
                  <i className="fas fa-plus" aria-hidden="true" />
                  {rowIcon}
                </span>Insert row above
              </button>
            </li>
            <li role="presentation">
              <button type="button" role="menuitem" tabIndex="-1" onClick={(e) => callEditorCommand(e, addRowAfterCommand)}>
                <span className="icon-stack">
                  {rowIcon}
                  <i className="fas fa-plus" aria-hidden="true" />
                </span>Insert row below
              </button>
            </li>
            <li role="presentation">
              <button
                type="button"
                role="menuitem"
                tabIndex="-1"
                onClick={(e) => callEditorCommand(e, moveRowCommand, {from: row, to: row - 1})}
                aria-disabled={row === 0 || null}
              >
                <span className="icon-stack">
                  <i className="fas fa-turn-down fa-rotate-270" aria-hidden="true" />
                  {rowIcon}
                </span>Move row up
              </button>
            </li>
            <li role="presentation">
              <button
                type="button"
                role="menuitem"
                tabIndex="-1"
                onClick={(e) => callEditorCommand(e, moveRowCommand, {from: row, to: row + 1})}
                aria-disabled={row === rowCount - 1 || null}
              >
                <span className="icon-stack">
                  {rowIcon}
                  <i className="fas fa-turn-up fa-rotate-90" aria-hidden="true" />
                </span>Move row down
              </button>
            </li>
            <li role="presentation">
              <button type="button" role="menuitem" tabIndex="-1" onClick={(e) => callEditorCommand(e, selectRowCommand, {index: row})}>
                <span className="icon-stack">
                  <i className="fas fa-table-columns fa-rotate-270 one" aria-hidden="true" />
                </span>Select row cells
              </button>
            </li>
          </ul>
        </li>
        <li onMouseLeave={() => subMenuExit(document.getElementById(`${editorId}colMenuB`))} role="presentation">
          <button
            type="button"
            role="menuitem"
            tabIndex="-1"
            className="tableSubMenu"
            id={`${editorId}colMenuB`}
            aria-controls={`${editorId}colMenu`}
            aria-expanded="false"
            aria-haspopup="true"
            onMouseEnter={subMenuOpen}
          ><i className="fas fa-table-columns" aria-hidden="true" />Columns<i className="fas fa-chevron-right" aria-hidden="true" />
          </button>
          <ul hidden id={`${editorId}colMenu`} role="menu">
            <li role="presentation">
              <button type="button" role="menuitem" tabIndex="-1" onClick={(e) => callEditorCommand(e, addColBeforeCommand)}>
                <span className="icon-line"><i className="fas fa-plus" aria-hidden="true" />{colIcon}</span>Insert column left
              </button>
            </li>
            <li role="presentation">
              <button type="button" role="menuitem" tabIndex="-1" onClick={(e) => callEditorCommand(e, addColAfterCommand)}>
                <span className="icon-line">{colIcon}<i className="fas fa-plus" aria-hidden="true" /></span>Insert column right
              </button>
            </li>
            <li role="presentation">
              <button
                type="button"
                role="menuitem"
                tabIndex="-1"
                onClick={(e) => callEditorCommand(e, moveColCommand, {from: col, to: col - 1})}
                aria-disabled={col === 0 || null}
              >
                <span className="icon-line"><i className="fas fa-turn-down fa-flip-horizontal" aria-hidden="true" />{colIcon}</span>Move column left
              </button>
            </li>
            <li role="presentation">
              <button
                type="button"
                role="menuitem"
                tabIndex="-1"
                onClick={(e) => callEditorCommand(e, moveColCommand, {from: col, to: col + 1})}
                aria-disabled={col === colCount - 1 || null}
              >
                <span className="icon-line">{colIcon}<i className="fas fa-turn-down" aria-hidden="true" /></span>Move column right
              </button>
            </li>
            <li role="presentation">
              <button
                type="button"
                role="menuitem"
                tabIndex="-1"
                onClick={(e) => callEditorCommand(e, selectColCommand, {index: col})}
              ><i className="fas fa-table-columns one" aria-hidden="true" />Select column cells
              </button>
            </li>
          </ul>
        </li>
        <li role="presentation">
          <button type="button" role="menuitem" tabIndex="-1" onClick={(e) => callEditorCommand(e, deleteSelectedCellsCommand)}>
            <i className="fas fa-delete-left" aria-hidden="true" />Delete cells
          </button>
        </li>
      </ul>
    </div>
  );
}
