import React, {useState, useId} from 'react';
import {editorViewCtx} from '@milkdown/core';
import {callCommand} from '@milkdown/utils';
import {TextSelection} from '@milkdown/prose/state';
import {commands} from '../milkdownCommands';
import {icons, labels} from './Details';

export default function LinkMenu({editor, editorId, active}) {
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
