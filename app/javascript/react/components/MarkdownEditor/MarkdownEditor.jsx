import React, {useEffect} from 'react';
import PropTypes from 'prop-types';
import {
  Editor, rootCtx, defaultValueCtx, editorViewCtx, serializerCtx,
} from '@milkdown/core';
import {
  Milkdown, MilkdownProvider, useEditor, useInstance,
} from '@milkdown/react';
import {history} from '@milkdown/plugin-history';
import {listener as listen, listenerCtx} from '@milkdown/plugin-listener';
import {commonmark} from '@milkdown/preset-commonmark';
import {gfm} from '@milkdown/preset-gfm';
import {replaceAll} from '@milkdown/utils';
import Button from './Button';

import './milkdown_editor.css';

function MilkdownCore({initialValue, onChange, onBlur}) {
  useEditor((root) => Editor
    .make()
    .config((ctx) => {
      ctx.set(rootCtx, root);
      ctx.set(defaultValueCtx, initialValue);

      const listener = ctx.get(listenerCtx);
      listener.markdownUpdated((_ctx, markdown, prevMarkdown) => {
        if (markdown !== prevMarkdown) onChange(markdown);
      });
      listener.blur((ctxx) => {
        const view = ctxx.get(editorViewCtx);
        const serializer = ctxx.get(serializerCtx);
        const markdown = serializer(view.state.doc);
        onBlur(markdown);
      });
    })
    .use([listen, commonmark, gfm, history]));
  return (
    <Milkdown />
  );
}

const defaultButtons = ['heading', 'bold', 'emph', 'link', 'code', 'spacer', 'ul', 'ol', 'quote', 'block', 'table', 'spacer', 'undo', 'redo'];

function MilkdownEditor({
  id, initialValue, replaceValue, onChange, onBlur, buttons = defaultButtons,
}) {
  const [loading, editor] = useInstance();

  useEffect(() => {
    if (editor && replaceValue) editor()?.action(replaceAll(replaceValue));
  }, [editor, replaceValue]);

  return (
    <>
      {!loading && (
        <div className="md_editor-buttons" role="menubar">
          {buttons.map((button, i) => (
            <Button editorId={id} key={button + buttons.slice(0, i).filter((b) => b === button).length} type={button} editor={editor} />
          ))}
        </div>
      )}
      <MilkdownCore initialValue={initialValue} onChange={onChange} onBlur={onBlur} />
    </>
  );
}

// <p className="screen-reader-only" role="status" aria-live="polite" id="menu-status">{status}</p>

const MarkdownEditor = React.forwardRef((props, ref) => (
  <div ref={ref} id={props.id} className="markdown_editor">
    <MilkdownProvider>
      <MilkdownEditor {...props} />
    </MilkdownProvider>
  </div>
));

MarkdownEditor.propTypes = {
  id: PropTypes.string.isRequired,
  initialValue: PropTypes.string.isRequired,
  newValue: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  onBlur: PropTypes.func.isRequired,
  buttons: PropTypes.arrayOf(PropTypes.oneOf(defaultButtons)),
};

MarkdownEditor.defaultProps = {
  buttons: defaultButtons,
  newValue: '',
};

export default MarkdownEditor;
