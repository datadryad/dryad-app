import React, {useState} from 'react';
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
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}tableOptMenu`).parentElement;
    if (!element.contains(e.target)) {
      closeMenu();
      document.removeEventListener('click', clickListener);
    }
  };

  const openMenu = (e) => {
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
  };

  const subMenuExit = (button) => {
    const menu = document.getElementById(button.getAttribute('aria-controls'));
    button.setAttribute('aria-expanded', false);
    menu.hidden = true;
  };

  const subMenuOpen = (e) => {
    document.querySelectorAll('.tableSubMenu').forEach((b) => subMenuExit(b));
    const menu = document.getElementById(e.currentTarget.getAttribute('aria-controls'));
    e.currentTarget.setAttribute('aria-expanded', true);
    menu.removeAttribute('hidden');
  };

  const leaveMenu = (e) => {
    if (e.currentTarget.contains(e.relatedTarget)) return;
    document.querySelectorAll('.tableSubMenu').forEach((b) => subMenuExit(b));
    closeMenu();
  };

  const callEditorCommand = (command, variables) => {
    editor()?.action(callCommand(command.key, variables));
    const view = editor()?.ctx.get(editorViewCtx);
    view.focus();
  };

  return (
    <div className="tableSelect" role="menuitem" onBlur={leaveMenu}>
      <button
        type="button"
        className="tableOptButton"
        title="Table menu"
        aria-label="Table menu"
        aria-expanded="false"
        aria-controls={`${editorId}tableOptMenu`}
        onClick={openMenu}
        disabled={!active}
      >
        <i className="fas fa-table-cells-large" style={{marginRight: '.5ch'}} />
        <i className="fas fa-chevron-down" />
      </button>
      <ul className="tableOptMenu" id={`${editorId}tableOptMenu`} hidden>
        <li onMouseLeave={() => subMenuExit(document.getElementById(`${editorId}rowMenuB`))}>
          <button
            type="button"
            className="tableSubMenu"
            id={`${editorId}rowMenuB`}
            aria-controls={`${editorId}rowMenu`}
            onMouseEnter={subMenuOpen}
          ><i className="fas fa-table-columns fa-rotate-270" />Rows<i className="fas fa-chevron-right" />
          </button>
          <ul hidden id={`${editorId}rowMenu`}>
            <li>
              <button type="button" onClick={() => callEditorCommand(addRowBeforeCommand)}>
                <span className="icon-stack">
                  <i className="fas fa-plus" />
                  {rowIcon}
                </span>Insert row above
              </button>
            </li>
            <li>
              <button type="button" onClick={() => callEditorCommand(addRowAfterCommand)}>
                <span className="icon-stack">
                  {rowIcon}
                  <i className="fas fa-plus" />
                </span>Insert row below
              </button>
            </li>
            <li>
              <button type="button" onClick={() => callEditorCommand(moveRowCommand, {from: row, to: row - 1})} disabled={row === 0 || null}>
                <span className="icon-stack">
                  <i className="fas fa-turn-down fa-rotate-270" />
                  {rowIcon}
                </span>Move row up
              </button>
            </li>
            <li>
              <button
                type="button"
                onClick={() => callEditorCommand(moveRowCommand, {from: row, to: row + 1})}
                disabled={row === rowCount - 1 || null}
              >
                <span className="icon-stack">
                  {rowIcon}
                  <i className="fas fa-turn-up fa-rotate-90" />
                </span>Move row down
              </button>
            </li>
            <li>
              <button type="button" onClick={() => callEditorCommand(selectRowCommand, {index: row})}>
                <span className="icon-stack">
                  <i className="fas fa-table-columns fa-rotate-270 one" />
                </span>Select row cells
              </button>
            </li>
          </ul>
        </li>
        <li onMouseLeave={() => subMenuExit(document.getElementById(`${editorId}colMenuB`))}>
          <button
            type="button"
            className="tableSubMenu"
            id={`${editorId}colMenuB`}
            aria-controls={`${editorId}colMenu`}
            onMouseEnter={subMenuOpen}
          ><i className="fas fa-table-columns" />Columns<i className="fas fa-chevron-right" />
          </button>
          <ul hidden id={`${editorId}colMenu`}>
            <li>
              <button type="button" onClick={() => callEditorCommand(addColBeforeCommand)}>
                <span className="icon-line"><i className="fas fa-plus" />{colIcon}</span>Insert column left
              </button>
            </li>
            <li>
              <button type="button" onClick={() => callEditorCommand(addColAfterCommand)}>
                <span className="icon-line">{colIcon}<i className="fas fa-plus" /></span>Insert column right
              </button>
            </li>
            <li>
              <button type="button" onClick={() => callEditorCommand(moveColCommand, {from: col, to: col - 1})} disabled={col === 0 || null}>
                <span className="icon-line"><i className="fas fa-turn-down fa-flip-horizontal" />{colIcon}</span>Move column left
              </button>
            </li>
            <li>
              <button
                type="button"
                onClick={() => callEditorCommand(moveColCommand, {from: col, to: col + 1})}
                disabled={col === colCount - 1 || null}
              >
                <span className="icon-line">{colIcon}<i className="fas fa-turn-down" /></span>Move column right
              </button>
            </li>
            <li>
              <button
                type="button"
                onClick={() => callEditorCommand(selectColCommand, {index: col})}
              ><i className="fas fa-table-columns one" />Select column cells
              </button>
            </li>
          </ul>
        </li>
        <li>
          <button type="button" onClick={() => callEditorCommand(deleteSelectedCellsCommand)}><i className="fas fa-delete-left" />Delete cells
          </button>
        </li>
      </ul>
    </div>
  );
}
