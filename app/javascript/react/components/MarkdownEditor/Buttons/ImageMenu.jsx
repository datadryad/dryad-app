import React, {useState, useId} from 'react';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {TextSelection} from '@milkdown/kit/prose/state';
import {commands} from '../milkdownCommands';
import {icons, labels} from './Details';

export default function ImageMenu({editor, editorId, active}) {
  const [text, setText] = useState('');
  const [src, setSrc] = useState('');
  const [showRemove, setRemove] = useState(false);
  const textId = useId();
  const imgId = useId();
  const prevId = useId();

  const inImage = (doc, schema, {from, to}) => {
    let found = null;
    let nesting = 0;
    doc.nodesBetween(from === to ? from - 1 : from, to, (node, pos) => {
      if (node.type === schema.nodes.image) {
        nesting += 1;
        found = {node, pos, nesting};
      }
    });
    return found;
  };

  const getSettings = () => {
    if (editor) {
      const view = editor()?.ctx.get(editorViewCtx);
      const {dispatch, state} = view;
      const {
        doc, selection, schema, tr,
      } = state;
      const isImage = inImage(doc, schema, selection);
      if (isImage) {
        setText(isImage.node.attrs.alt);
        setSrc(isImage.node.attrs.src);
        setRemove(true);
        dispatch(tr);
      } else {
        setText(doc.textBetween(selection.from, selection.to));
      }
    }
  };

  const uploadImage = () => {
    const file = document.getElementById(imgId).files[0];
    const reader = new FileReader();
    reader.addEventListener('load', () => {
      setSrc(reader.result);
    });
    if (file) {
      reader.readAsDataURL(file);
    }
  };

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}imageMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.hidden = true;
    setText('');
    setSrc('');
    document.getElementById(`${editorId}imageForm`).reset();
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}imageMenu`).parentElement;
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
      document.getElementById(`${editorId}imageMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
  };

  const removeImage = () => {
    setText('');
    setSrc('');
    document.getElementById(`${editorId}imageForm`).reset();
    const view = editor()?.ctx.get(editorViewCtx);
    editor()?.action(callCommand(commands.image.key));
    view.focus();
  };

  const submit = (e) => {
    e.preventDefault();
    closeMenu();
    document.removeEventListener('click', clickListener);
    let command = commands.image;
    const view = editor()?.ctx.get(editorViewCtx);
    const {dispatch, state} = view;
    const {
      doc, selection, schema, tr,
    } = state;
    if (inImage(doc, schema, selection)) {
      command = commands.imageEdit;
    }
    tr.setSelection(TextSelection.create(doc, selection.from, selection.to));
    dispatch(tr);
    editor()?.action(callCommand(command.key, {src, alt: text}));
    view.focus();
  };

  return (
    <div className="imageSelect" role="menuitem">
      <button
        type="button"
        className={active ? 'active' : undefined}
        title={labels.image}
        aria-label={labels.image}
        aria-expanded="false"
        aria-controls={`${editorId}imageMenu`}
        onClick={openMenu}
      >{icons.image}
      </button>
      <div className="imageMenu" id={`${editorId}imageMenu`} hidden>
        <form id={`${editorId}imageForm`} onSubmit={submit}>
          <p><label htmlFor={textId}>Alt text</label>
            <textarea id={textId} rows="1" value={text} onChange={(e) => setText(e.target.value)} required />
          </p>
          <input
            id={imgId}
            type="file"
            accept="image/gif, image/png, image/jpg, image/jpeg, image/svg+xml, .gif, .png, .jpg, .jpeg, .svg, .svgz"
            aria-label="Upload image file"
            onChange={uploadImage}
            required
          />
          <div className="buttons">
            <button type="submit">Save</button>
            {showRemove && <button type="button" onClick={removeImage}>Remove</button>}
            <img id={prevId} src={src} alt="" aria-hidden="true" />
          </div>
          <p>Alt text and image required</p>
        </form>
      </div>
    </div>
  );
}
