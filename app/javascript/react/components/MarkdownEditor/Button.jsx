import React, {useState, useEffect} from 'react';
import {useSelect} from 'downshift';
import {editorViewCtx} from '@milkdown/core';
import {$command, callCommand} from '@milkdown/utils';
/* eslint-disable import/no-unresolved */
import {TextSelection} from '@milkdown/prose/state';
import {wrapInList} from '@milkdown/prose/schema-list';
/* eslint-enable import/no-unresolved */
import {redoCommand, undoCommand} from '@milkdown/plugin-history';
import {
  // toggleMark,
  toggleEmphasisCommand,
  toggleStrongCommand,
  toggleInlineCodeCommand,
  toggleLinkCommand,
  updateLinkCommand,
  wrapInBlockquoteCommand,
  wrapInHeadingCommand,
  createCodeBlockCommand,
  bulletListSchema,
  orderedListSchema,
  liftListItemCommand,
  sinkListItemCommand,
} from '@milkdown/preset-commonmark';
import {
  insertTableCommand,
  toggleStrikethroughCommand,
} from '@milkdown/preset-gfm';

export const bulletWrapCommand = $command('BulletListWrap', (ctx) => () => wrapInList(bulletListSchema.type(ctx)));
export const orderWrapCommand = $command('OrderedListWrap', (ctx) => () => wrapInList(orderedListSchema.type(ctx)));

const commands = {
  undo: undoCommand,
  redo: redoCommand,
  strong: toggleStrongCommand,
  emphasis: toggleEmphasisCommand,
  inlineCode: toggleInlineCodeCommand,
  strike: toggleStrikethroughCommand,
  bullet_list: bulletWrapCommand,
  ordered_list: orderWrapCommand,
  outdent: liftListItemCommand,
  indent: sinkListItemCommand,
  blockquote: wrapInBlockquoteCommand,
  code_block: createCodeBlockCommand,
  table: insertTableCommand,
  heading: wrapInHeadingCommand,
};

const labels = {
  undo: 'Undo',
  redo: 'Redo',
  strong: 'Bold',
  emphasis: 'Italic',
  link: 'Link',
  inlineCode: 'Code',
  strike: 'Strikethrough text',
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
  undo: <i className="fa fa-undo" aria-hidden="true" />,
  redo: <i className="fa fa-repeat" aria-hidden="true" />,
  strong: <i className="fa fa-bold" aria-hidden="true" />,
  emphasis: <i className="fa fa-italic" aria-hidden="true" />,
  link: <i className="fa fa-link" aria-hidden="true" />,
  inlineCode: <i className="fa fa-terminal" aria-hidden="true" />,
  strike: <i className="fa fa-strikethrough" aria-hidden="true" />,
  bullet_list: <i className="fa fa-list" aria-hidden="true" />,
  ordered_list: <i className="fa fa-list-ol" aria-hidden="true" />,
  indent: <i className="fa fa-indent" aria-hidden="true" />,
  outdent: <i className="fa fa-outdent" aria-hidden="true" />,
  blockquote: <i className="fa fa-quote-left" aria-hidden="true" />,
  code_block: <i className="fa fa-code" aria-hidden="true" />,
  table: <i className="fa fa-table" aria-hidden="true" />,
};

function LinkMenu({editor, editorId, active}) {
  const [text, setText] = useState('');
  const [url, setUrl] = useState('');
  const [showRemove, setRemove] = useState(false);

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

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}linkMenu`).parentElement;
    if (!element.contains(e.target)) {
      closeMenu();
      document.removeEventListener('click', clickListener);
    }
  };

  const openMenu = (e) => {
    getSettings();
    e.currentTarget.setAttribute('aria-expanded', true);
    document.getElementById(`${editorId}linkMenu`).removeAttribute('hidden');
    document.addEventListener('click', clickListener);
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
    editor()?.action(callCommand(toggleLinkCommand.key));
    view.focus();
  };

  const submit = () => {
    closeMenu();
    document.removeEventListener('click', clickListener);
    checkNewText();
    let command = toggleLinkCommand;
    const view = editor()?.ctx.get(editorViewCtx);
    const {dispatch, state} = view;
    const {
      doc, selection, schema, tr,
    } = state;
    const {from, to} = selection;
    if (doc.rangeHasMark(from, to, schema.marks.link)) {
      command = updateLinkCommand;
    }
    tr.setSelection(TextSelection.create(doc, from, to));
    dispatch(tr);
    editor()?.action(callCommand(command.key, {href: url}));
    view.focus();
  };

  return (
    <div className="linkSelect" role="menuitem">
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
        <label>Link text <input type="text" value={text} onChange={(e) => setText(e.target.value)} /></label>
        <label>URL <input type="text" value={url} onChange={(e) => setUrl(e.target.value)} /></label>
        <div className="buttons">
          <button type="button" onClick={submit}>Save</button>
          {showRemove && <button type="button" onClick={removeLink}>Remove</button>}
        </div>
      </div>
    </div>
  );
}

function Table({editor, editorId, active}) {
  const [rows, setRows] = useState([1, 2, 3, 4, 5, 6]);
  const [cols, setCols] = useState([1, 2, 3, 4, 5, 6]);
  const [colNum, setColNum] = useState(0);
  const [rowNum, setRowNum] = useState(0);

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}tableMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.hidden = true;
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}tableMenu`).parentElement;
    if (!element.contains(e.target)) {
      closeMenu();
      document.removeEventListener('click', clickListener);
    }
  };

  const openMenu = (e) => {
    e.currentTarget.setAttribute('aria-expanded', true);
    document.getElementById(`${editorId}tableMenu`).removeAttribute('hidden');
    document.addEventListener('click', clickListener);
  };

  const select = (e) => {
    const col = Number(e.currentTarget.dataset.col);
    const row = Number(e.currentTarget.parentElement.dataset.row);
    document.querySelectorAll('.tableEntry span').forEach((s) => {
      if (s.dataset.col <= col && s.parentElement.dataset.row <= row) s.classList.add('hovering');
    });
    if (col === cols.length) setCols((c) => [...c, col + 1]);
    if (row === rows.length) setRows((r) => [...r, row + 1]);
    setColNum(col);
    setRowNum(row);
  };

  const deselect = () => {
    document.querySelectorAll('.tableEntry span').forEach((s) => s.classList.remove('hovering'));
    setColNum(0);
    setRowNum(0);
  };

  const submit = () => {
    closeMenu();
    document.removeEventListener('click', clickListener);
    const view = editor()?.ctx.get(editorViewCtx);
    editor()?.action(callCommand(commands.table.key, {row: rowNum, col: colNum}));
    view.focus();
  };

  return (
    <div className="tableSelect" role="menuitem">
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
        <div className="screen-reader-only">
          <input type="text" aria-label="Number of rows" value={rowNum} onChange={(e) => setRowNum(e.target.value)} />
          <input type="text" aria-label="Number of columns" value={colNum} onChange={(e) => setColNum(e.target.value)} />
          <button type="button" onClick={submit} aria-label={`Insert ${rowNum} x ${colNum} table`} />
        </div>
        <div className="tableEntry">
          {rows.map((r) => (
            <div key={`row${r}`} data-row={r}>
              {cols.map((c) => (
                <span key={`col${c}`} data-col={c} onClick={submit} onMouseEnter={select} onMouseLeave={deselect} aria-hidden="true" />
              ))}
            </div>
          ))}
        </div>
        {(rowNum && colNum) ? <p style={{fontSize: '.8rem', textAlign: 'center', margin: '.5rem auto'}}>{rowNum} x {colNum}</p> : ''}
      </div>
    </div>
  );
}

function Heading({editor, active, headingLevel}) {
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
      editor()?.action(callCommand(commands.heading.key, newSelectedItem));
      const view = editor()?.ctx.get(editorViewCtx);
      view.focus();
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

function Button({
  type, active, disabled, editor, editorId, headingLevel,
}) {
  if (type === 'spacer') return <span className="spacer" />;
  if (type === 'link') return <LinkMenu active={active} editor={editor} editorId={editorId} />;
  if (type === 'table') return <Table active={active} editor={editor} editorId={editorId} />;
  if (type === 'heading') return <Heading active={active} editor={editor} headingLevel={headingLevel} />;
  if (type.includes('list')) return <List active={active} editor={editor} type={type} />;
  return (
    <button
      type="button"
      className={active ? 'active' : undefined}
      disabled={disabled ? 'disabled' : false}
      title={labels[type]}
      aria-label={labels[type]}
      role="menuitem"
      onClick={() => {
        editor()?.action(callCommand(commands[type].key));
        const view = editor()?.ctx.get(editorViewCtx);
        view.focus();
      }}
    >{icons[type]}
    </button>
  );
}

export default Button;