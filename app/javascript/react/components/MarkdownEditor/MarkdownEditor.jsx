import React, {useEffect, useState} from 'react';
import PropTypes from 'prop-types';
import {
  Editor, rootCtx, defaultValueCtx, editorViewCtx, serializerCtx, schemaCtx,
} from '@milkdown/core';
import {
  Milkdown, MilkdownProvider, useEditor, useInstance,
} from '@milkdown/react';
import {history} from '@milkdown/plugin-history';
import {listener as listen, listenerCtx} from '@milkdown/plugin-listener';
import {trailing} from '@milkdown/plugin-trailing';
import {commonmark} from '@milkdown/preset-commonmark';
import {gfm} from '@milkdown/preset-gfm';
import {replaceAll} from '@milkdown/utils';
import dryadConfig from './dryadConfig';
import {selectionListener, selectionCtx} from './selectionListener';
import Button from './Button';

function MilkdownCore({
  initialValue, onChange, onBlur, setSelection,
}) {
  useEditor((root) => Editor
    .make()
    .config(dryadConfig)
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
      const slistener = ctx.get(selectionCtx);
      slistener.selection((ctxx, selection, doc) => {
        const schema = ctxx.get(schemaCtx);
        setSelection({doc, selection, schema});
      });
    })
    .use([listen, commonmark, gfm, history, trailing, selectionListener]));
  return (
    <Milkdown />
  );
}

const defaultButtons = ['heading', 'strong', 'emphasis', 'link', 'inlineCode', 'spacer',
  'bullet_list', 'ordered_list', 'blockquote', 'code_block', 'table', 'spacer', 'undo', 'redo'];

function MilkdownEditor({
  id, initialValue, replaceValue, onChange, onBlur, buttons = defaultButtons,
}) {
  const [loading, editor] = useInstance();

  const [selection, setSelection] = useState(null);
  const [active, setActive] = useState([]);
  const [headingLevel, setHeadingLevel] = useState(0);

  useEffect(() => {
    if (editor && replaceValue) editor()?.action(replaceAll(replaceValue));
  }, [editor, replaceValue]);

  useEffect(() => {
    if (selection) {
      setActive([]);
      const list = [];
      const {doc, selection: sel, schema} = selection;
      const {from, to} = sel;
      const {path, parent} = doc.resolve(from);
      path.forEach((i) => i.type && list.push(i.type.name));
      Object.keys(schema.marks).forEach((m) => {
        if (doc.rangeHasMark(from === to ? from - 1 : from, to, schema.marks[m])) list.push(schema.marks[m].name);
      });
      setActive(list);
      setHeadingLevel(parent.attrs?.level || 0);
    }
  }, [selection]);

  return (
    <>
      {!loading && (
        <div className="md_editor-buttons" role="menubar">
          {buttons.map((button, i) => (
            <Button
              active={active.includes(button)}
              headingLevel={headingLevel}
              editorId={id}
              key={button + buttons.slice(0, i).filter((b) => b === button).length}
              type={button}
              editor={editor}
            />
          ))}
        </div>
      )}
      <MilkdownCore initialValue={initialValue} onChange={onChange} onBlur={onBlur} setSelection={setSelection} />
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
