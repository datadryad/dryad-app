import React, {useState, useEffect} from 'react';
import {range} from 'lodash';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {commands} from '../milkdownCommands';
import {commands as mdCommands} from '../codeKeymap';
import {icons, labels} from './Details';
import TableMenu from './TableMenu';

export default function Table({
  active, editor, mdEditor, activeEditor, editorId,
}) {
  const startNum = range(1, 6);
  const [rows, setRows] = useState(startNum);
  const [cols, setCols] = useState(startNum);
  const [tableNums, setNums] = useState([0, 0]);

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}tableMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.hidden = true;
    setNums([0, 0]);
    setCols(startNum);
    setRows(startNum);
  };

  const leaveMenu = (e) => {
    if (e.currentTarget.contains(e.relatedTarget)) return;
    closeMenu();
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}tableMenu`).parentElement;
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
      document.getElementById(`${editorId}tableMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
  };

  const select = (e) => {
    const col = Number(e.currentTarget.dataset.col);
    const row = Number(e.currentTarget.parentElement.dataset.row);
    setNums([col, row]);
  };

  const deselect = () => {
    setNums([0, 0]);
  };

  const submit = (e) => {
    if (e) e.preventDefault();
    const [col, row] = tableNums;
    if (activeEditor === 'visual') {
      const view = editor()?.ctx.get(editorViewCtx);
      editor()?.action(callCommand(commands.table.key, {row, col}));
      view.focus();
    } else if (activeEditor === 'markdown') {
      mdCommands.table(mdEditor, row, col);
      mdEditor.focus();
    }
    closeMenu();
    document.removeEventListener('click', clickListener);
  };

  useEffect(() => {
    const [col, row] = tableNums;
    document.querySelectorAll('.tableEntry span').forEach((s) => s.classList.remove('hovering'));
    if (col > 0 || row > 0) {
      document.querySelectorAll('.tableEntry span').forEach((s) => {
        if (s.dataset.col <= col && s.parentElement.dataset.row <= row) s.classList.add('hovering');
      });
      if (col === cols.length) setCols((c) => Array.from(new Set([...c, col + 1])));
      if (row === rows.length) setRows((r) => Array.from(new Set([...r, row + 1])));
      if (col > cols.length) setCols(() => range(1, col + 1));
      if (row > rows.length) setRows(() => range(1, row + 1));
    }
  }, tableNums);

  return (
    <>
      <div className="tableSelect" role="menuitem" onBlur={leaveMenu}>
        <button
          type="button"
          className={active ? 'active' : undefined}
          aria-label={labels.table}
          title={labels.table}
          aria-expanded="false"
          aria-controls={`${editorId}tableMenu`}
          onClick={openMenu}
        >{icons.table}
        </button>
        <div
          className="tableMenu"
          id={`${editorId}tableMenu`}
          hidden
          style={{width: `${2.1 + (1.3 * cols.length)}rem`, height: `${3 + (1.3 * rows.length)}rem`}}
        >
          <div className="tableEntry">
            {rows.map((r) => (
              <div key={`row${r}`} data-row={r}>
                {cols.map((c) => (
                  <span key={`col${c}`} data-col={c} tabIndex={-1} onClick={submit} onMouseEnter={select} onMouseLeave={deselect} aria-hidden />
                ))}
              </div>
            ))}
          </div>
          <form onSubmit={submit}>
            <p className="tableMenuButtons">
              <input type="text" aria-label="Number of rows" value={tableNums[1]} onChange={(e) => setNums(([c]) => [c, Number(e.target.value)])} />
              x
              <input
                type="text"
                aria-label="Number of columns"
                value={tableNums[0]}
                onChange={(e) => setNums(([, r]) => [Number(e.target.value), r])}
              />
              <button type="submit" className="o-button__plain-textlink" aria-label={`Insert a ${tableNums[1]} x ${tableNums[0]} table`}>
                <i className="fas fa-square-plus" />
              </button>
            </p>
          </form>
        </div>
      </div>
      <TableMenu {...{active, editor, editorId}} />
    </>
  );
}
