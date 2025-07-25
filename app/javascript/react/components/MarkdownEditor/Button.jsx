import React, {useState, useEffect, useId} from 'react';
import {useSelect} from 'downshift';
import {range} from 'lodash';
import {editorViewCtx} from '@milkdown/core';
import {callCommand} from '@milkdown/utils';
// eslint-disable-next-line import/no-unresolved
import {TextSelection} from '@milkdown/prose/state';
import {commands} from './milkdownCommands';
import {commands as mdCommands} from './codeKeymap';

const labels = {
  undo: 'Undo',
  redo: 'Redo',
  strong: 'Bold',
  emphasis: 'Italic',
  link: 'Add link',
  inlineCode: 'Monospace',
  strike_through: 'Strikethrough text',
  bullet_list: 'Create list',
  ordered_list: 'Create numbered list',
  indent: 'Indent list',
  outdent: 'Remove indent',
  blockquote: 'Make quote',
  code_block: 'Insert code block',
  table: 'Insert table',
  heading: 'Set heading',
};

const icons = {
  undo: <i className="fas fa-undo" aria-hidden="true" />,
  redo: <i className="fas fa-rotate-right" aria-hidden="true" />,
  strong: <i className="fas fa-bold" aria-hidden="true" />,
  emphasis: <i className="fas fa-italic" aria-hidden="true" />,
  link: <i className="fas fa-link" aria-hidden="true" />,
  inlineCode: <i className="fas fa-terminal" aria-hidden="true" />,
  strike_through: <i className="fas fa-strikethrough" aria-hidden="true" />,
  bullet_list: <i className="fas fa-list" aria-hidden="true" />,
  ordered_list: <i className="fas fa-list-ol" aria-hidden="true" />,
  indent: <i className="fas fa-indent" aria-hidden="true" />,
  outdent: <i className="fas fa-outdent" aria-hidden="true" />,
  blockquote: <i className="fas fa-quote-left" aria-hidden="true" />,
  code_block: <i className="fas fa-code" aria-hidden="true" />,
  table: <i className="fas fa-table" aria-hidden="true" />,
};

function LinkMenu({editor, editorId, active}) {
  const [text, setText] = useState('');
  const [url, setUrl] = useState('');
  const [showRemove, setRemove] = useState(false);
  const textId = useId();
  const urlId = useId();

  const getLink = (doc, pos, schema) => {
    const $pos = doc.resolve(pos);
    const {parent, parentOffset} = $pos;
    const start = parent.childAfter(parentOffset);
    if (!start.node) return null;

    const link = start.node.marks.find((mark) => mark.type === schema.marks.link);
    if (!link) return null;

    const {href} = link.attrs;
    let startIndex = $pos.index();
    let startPos = $pos.start() + start.offset;
    let endIndex = startIndex + 1;
    let endPos = startPos + start.node.nodeSize;
    while (startIndex > 0 && link.isInSet(parent.child(startIndex - 1).marks)) {
      startIndex -= 1;
      startPos -= parent.child(startIndex).nodeSize;
    }
    while (endIndex < parent.childCount && link.isInSet(parent.child(endIndex).marks)) {
      endPos += parent.child(endIndex).nodeSize;
      endIndex += 1;
    }
    return {from: startPos, to: endPos, href};
  };

  const getSettings = () => {
    if (editor) {
      const view = editor()?.ctx.get(editorViewCtx);
      const {dispatch, state} = view;
      const {
        doc, selection, schema, tr,
      } = state;
      const {from: start, to: end} = selection;
      if (doc.rangeHasMark(start, end === start ? end + 1 : end, schema.marks.link)) {
        const {from, to, href} = getLink(doc, start, schema);
        setText(doc.textBetween(from, to));
        setUrl(href);
        setRemove(true);
        tr.setSelection(TextSelection.create(doc, from, to));
        dispatch(tr);
      } else {
        setText(doc.textBetween(start, end));
      }
    }
  };

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}linkMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.hidden = true;
    setText('');
    setUrl('');
  };

  const leaveMenu = (e) => {
    if (e.currentTarget.contains(e.relatedTarget)) return;
    closeMenu();
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}linkMenu`).parentElement;
    if (!element.contains(e.target)) {
      closeMenu();
      document.removeEventListener('click', clickListener);
    }
  };

  const openMenu = (e) => {
    if (e.currentTarget.getAttribute('aria-expanded') === 'true') {
      closeMenu();
    } else {
      getSettings();
      e.currentTarget.setAttribute('aria-expanded', true);
      document.getElementById(`${editorId}linkMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
  };

  const checkNewText = () => {
    const view = editor()?.ctx.get(editorViewCtx);
    const {dispatch, state} = view;
    const {selection, tr} = state;
    const {from, to} = selection;
    if (to - from < text.length) {
      tr.insertText(text, from, to);
      dispatch(tr);
    }
  };

  const removeLink = () => {
    const view = editor()?.ctx.get(editorViewCtx);
    editor()?.action(callCommand(commands.link.key));
    view.focus();
  };

  const submit = () => {
    closeMenu();
    document.removeEventListener('click', clickListener);
    checkNewText();
    let command = commands.link;
    const view = editor()?.ctx.get(editorViewCtx);
    const {dispatch, state} = view;
    const {
      doc, selection, schema, tr,
    } = state;
    const {from, to} = selection;
    if (doc.rangeHasMark(from, to, schema.marks.link)) {
      command = commands.linkEdit;
    }
    tr.setSelection(TextSelection.create(doc, from, to));
    dispatch(tr);
    editor()?.action(callCommand(command.key, {href: url}));
    view.focus();
  };

  return (
    <div className="linkSelect" role="menuitem" onBlur={leaveMenu}>
      <button
        type="button"
        className={active ? 'active' : undefined}
        title={labels.link}
        aria-label={labels.link}
        aria-expanded="false"
        aria-controls={`${editorId}linkMenu`}
        onClick={openMenu}
      >{icons.link}
      </button>
      <div className="linkMenu" id={`${editorId}linkMenu`} hidden>
        <label htmlFor={textId}>Link text <input id={textId} type="text" value={text} onChange={(e) => setText(e.target.value)} /></label>
        <label htmlFor={urlId}>URL <input id={urlId} type="text" value={url} onChange={(e) => setUrl(e.target.value)} /></label>
        <div className="buttons">
          <button type="button" onClick={submit}>Save</button>
          {showRemove && <button type="button" onClick={removeLink}>Remove</button>}
        </div>
      </div>
    </div>
  );
}

function List({type, editor, active}) {
  const isInList = (doc, schema, {from, to}) => {
    let found = null;
    let nesting = 0;
    doc.nodesBetween(from === to ? from - 1 : from, to, (node, pos) => {
      if (node.type === schema.nodes.ordered_list
        || node.type === schema.nodes.bullet_list) {
        nesting += 1;
        found = {node, pos, nesting};
      }
    });
    return found;
  };

  const changeListType = ({state, dispatch}, pos, ltype) => {
    const [lType] = ltype.name.split('_');
    const {doc, tr} = state;
    const list = doc.resolve(pos - 2);
    const start = list.start(list.depth - 1);
    const end = list.end(list.depth - 1);
    doc.nodesBetween(start, end, (n, p) => {
      if (n.type.name === 'list_item') {
        const resolved = doc.resolve(p);
        const parent = resolved.before();
        if (parent === pos && n.attrs.listType !== lType) {
          tr.setNodeMarkup(p, null, n.type.defaultAttrs);
          tr.setNodeMarkup(pos, ltype);
        }
      }
    });
    dispatch(tr);
    return true;
  };

  const listWizard = () => {
    const view = editor()?.ctx.get(editorViewCtx);
    const {state} = view;
    const {doc, selection, schema} = state;
    const existing = isInList(doc, schema, selection);
    if (existing) {
      if (existing.node.type === schema.nodes[type]) {
        Array.from({length: existing.nesting}, () => editor()?.action(callCommand(commands.outdent.key)));
      } else {
        changeListType(view, existing.pos, schema.nodes[type]);
      }
    } else {
      editor()?.action(callCommand(commands[type].key));
    }
    view.focus();
  };

  return (
    <button
      type="button"
      className={active ? 'active' : undefined}
      title={labels[type]}
      aria-label={labels[type]}
      role="menuitem"
      onClick={listWizard}
    >{icons[type]}
    </button>
  );
}

function Toggle({
  type, editor, active, disabled,
}) {
  const callEditorCommand = () => {
    const view = editor()?.ctx.get(editorViewCtx);
    const {dispatch, state} = view;
    const {
      doc, selection, schema, tr,
    } = state;
    const {from: start, to: end} = selection;
    if (doc.rangeHasMark(start, end === start ? end + 1 : end, schema.marks[type])) {
      const {parent} = doc.resolve(start);
      let from = start;
      let to = end;
      while (from > 0 && !doc.textBetween(from - 1, start).replace(/[ ]/g, '').length) {
        from -= 1;
      }
      while (to < parent.childCount && !doc.textBetween(end, to + 1).replace(/[ ]/g, '').length) {
        to += 1;
      }
      tr.setSelection(TextSelection.create(doc, from, to));
      dispatch(tr);
    }
    editor()?.action(callCommand(commands[type].key));
    view.focus();
  };

  return (
    <button
      type="button"
      className={active ? 'active' : undefined}
      disabled={disabled}
      title={labels[type]}
      aria-label={labels[type]}
      role="menuitem"
      onClick={callEditorCommand}
    >{icons[type]}
    </button>
  );
}

function Table({
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
                <span key={`col${c}`} data-col={c} tabIndex={-1} onClick={submit} onMouseEnter={select} onMouseLeave={deselect} aria-hidden="true" />
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
  );
}

function Heading({
  active, editor, mdEditor, activeEditor, headingLevel,
}) {
  const [selectedItem, setSelectedItem] = React.useState(headingLevel);
  useEffect(() => {
    setSelectedItem(headingLevel);
  }, [headingLevel]);
  const items = [1, 2, 3, 4, 5, 6, 0];
  const {
    isOpen,
    getToggleButtonProps,
    getMenuProps,
    getItemProps,
    highlightedIndex,
  } = useSelect({
    items,
    selectedItem,
    onSelectedItemChange: ({selectedItem: newSelectedItem}) => {
      setSelectedItem(newSelectedItem);
      if (activeEditor === 'visual') {
        editor()?.action(callCommand(commands.heading.key, newSelectedItem));
        const view = editor()?.ctx.get(editorViewCtx);
        view.focus();
      } else if (activeEditor === 'markdown') {
        mdCommands[`heading${newSelectedItem}`](mdEditor);
        mdEditor.focus();
      }
    },
  });
  return (
    <div className="headingSelect" role="menuitem">
      <div
        className={`headingButton${active ? ' active' : ''}`}
        role="button"
        aria-label={labels.heading}
        title={labels.heading}
        {...getToggleButtonProps({'aria-labelledby': null})}
        tabIndex="0"
      >
        <span>{selectedItem ? ((selectedItem === 1 && 'Title') || `Heading ${selectedItem}`) : 'Heading'}</span>
        <i className={`fa ${isOpen ? 'fa-chevron-up' : 'fa-chevron-down'}`} />
      </div>
      <ul hidden={!isOpen} {...getMenuProps()} className="headingMenu">
        {isOpen
          && items.map((item, index) => (
            <li
              className={`h${item} ${highlightedIndex === index ? 'highlighted ' : ''}${selectedItem === item ? 'selected' : ''}`}
              key={`heading${item}`}
              {...getItemProps({item, index})}
            >
              {(item === 0 && 'Normal text') || (item === 1 && 'Title') || `Heading ${item}`}
            </li>
          ))}
      </ul>
    </div>
  );
}

function Button({
  type, active, disabled, editorId, activeEditor, editor, mdEditor, headingLevel,
}) {
  if (type === 'spacer') return <span className="spacer" />;
  if (activeEditor === 'visual') {
    if (type === 'link') return <LinkMenu active={active} editor={editor} editorId={editorId} />;
    if (type.includes('list')) return <List active={active} editor={editor} type={type} />;
    if (['strong', 'emphasis', 'inlineCode', 'strike_through'].includes(type)) {
      return <Toggle active={active} editor={editor} type={type} disabled={disabled} />;
    }
  }
  const sharedProps = {
    active, editor, mdEditor, activeEditor,
  };
  if (type === 'table') return <Table {...sharedProps} editorId={editorId} />;
  if (type === 'heading') return <Heading {...sharedProps} headingLevel={headingLevel} />;

  const callEditorCommand = () => {
    if (activeEditor === 'visual') {
      editor()?.action(callCommand(commands[type].key));
      const view = editor()?.ctx.get(editorViewCtx);
      view.focus();
    } else if (activeEditor === 'markdown') {
      mdCommands[type](mdEditor);
      mdEditor.focus();
    }
  };

  return (
    <button
      type="button"
      className={active ? 'active' : undefined}
      disabled={disabled || (activeEditor === 'markdown' && type.includes('list') && active)}
      title={labels[type]}
      aria-label={labels[type]}
      role="menuitem"
      onClick={callEditorCommand}
    >{icons[type]}
    </button>
  );
}

export default Button;
