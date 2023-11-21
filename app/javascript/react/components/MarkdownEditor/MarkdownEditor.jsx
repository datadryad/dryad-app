import React, {useEffect, useState} from 'react';
import PropTypes from 'prop-types';
import {
  Editor, rootCtx, defaultValueCtx, schemaCtx, serializerCtx, editorViewCtx, remarkStringifyOptionsCtx, rootDOMCtx,
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
import CodeEditor from './CodeEditor';
import Button from './Button';
import dryadConfig from './milkdownConfig';
import {selectionListener, selectionCtx} from './selectionListener';
import {
  bulletWrapCommand, bulletWrapKeymap, orderWrapCommand, orderWrapKeymap,
} from './milkdownCommands';

const allowSpans = [
  'autolink',
  'destinationLiteral',
  'destinationRaw',
  'reference',
  'titleQuote',
  'titleApostrophe',
  'paragraph',
  'listItem',
];

function MilkdownCore({
  initialValue, onChange, setActive, setLevel,
}) {
  useEditor((root) => Editor
    .make()
    .config(dryadConfig)
    .config((ctx) => {
      ctx.set(rootCtx, root);
      ctx.set(defaultValueCtx, initialValue);
      ctx.set(remarkStringifyOptionsCtx, {
        fences: true,
        rule: '-',
        handlers: {
          paragraph: (node, _, state, info) => {
            const exit = state.enter('paragraph');
            const value = state.containerPhrasing(node, info);
            exit();
            return value;
          },
        },
        unsafe: [
          {character: '_', notInConstruct: allowSpans},
          {before: '[\\s]', character: '_'},
          {character: '_', after: '[\\s]'},
        ],
      });
      const listener = ctx.get(listenerCtx);
      listener.markdownUpdated((_ctx, markdown, prevMarkdown) => {
        if (markdown !== prevMarkdown) onChange(markdown);
      });
      const slistener = ctx.get(selectionCtx);
      slistener.selection((ctxx, selection, doc) => {
        setActive([]);
        const list = [];
        const schema = ctxx.get(schemaCtx);
        const {from, to} = selection;
        const {path, parent} = doc.resolve(from);
        path.forEach((i) => i.type && list.push(i.type.name));
        Object.keys(schema.marks).forEach((m) => {
          if (doc.rangeHasMark(from === to ? from - 1 : from, to, schema.marks[m])) list.push(schema.marks[m].name);
        });
        setActive(list);
        setLevel(parent.attrs?.level || 0);
      });
    })
    .use([bulletWrapCommand, bulletWrapKeymap, orderWrapCommand, orderWrapKeymap])
    .use([listen, commonmark, gfm, history, trailing, selectionListener]));
  return (
    <Milkdown />
  );
}

const defaultButtons = ['heading', 'strong', 'emphasis', 'link', 'inlineCode', 'spacer',
  'table', 'blockquote', 'code_block', 'bullet_list', 'ordered_list', 'indent', 'outdent', 'spacer', 'undo', 'redo'];

function MilkdownEditor({
  id, initialValue, replaceValue, onChange, buttons = defaultButtons,
}) {
  const [loading, editor] = useInstance();

  const [editType, setEditType] = useState('visual');
  const [active, setActive] = useState([]);
  const [headingLevel, setHeadingLevel] = useState(0);
  const [md, setMD] = useState(initialValue);
  const [mdEditor, setMDEditor] = useState(null);

  const activeList = () => active.some((a) => a && a.includes('list'));

  const saveMarkdown = (markdown) => {
    setMD(markdown);
    onChange(markdown);
  };

  const getMarkdown = () => editor()?.action((ctx) => {
    const editorView = ctx.get(editorViewCtx);
    const serializer = ctx.get(serializerCtx);
    return serializer(editorView.state.doc);
  });

  useEffect(() => {
    editor()?.action((ctx) => {
      const visEditor = ctx.get(rootDOMCtx).parentElement;
      if (editType === 'markdown') {
        setActive([]);
        visEditor.hidden = true;
      } else {
        setActive([]);
        visEditor.removeAttribute('hidden');
        editor()?.action(replaceAll(md));
      }
    });
  }, [editType]);

  useEffect(() => {
    if (editor && replaceValue) editor()?.action(replaceAll(replaceValue));
  }, [editor, replaceValue]);

  return (
    <>
      {!loading && (
        <div className="md_editor-buttons" role="menubar">
          <div className="md_editor-toolbar">
            {buttons.map((button, i) => (
              <Button
                active={active.includes(button) || (editType === 'markdown' && button.includes('list') && activeList())}
                disabled={button.includes('dent') && !activeList()}
                headingLevel={headingLevel}
                editorId={id}
                key={button + buttons.slice(0, i).filter((b) => b === button).length}
                type={button}
                editor={editor}
                mdEditor={mdEditor}
                activeEditor={editType}
              />
            ))}
          </div>
          <div className="md_editor-toggle">
            <button type="button" onClick={() => setEditType('markdown')} disabled={editType === 'markdown'}>Markdown</button>
            <button type="button" onClick={() => setEditType('visual')} disabled={editType === 'visual'}>Rich text</button>
          </div>
        </div>
      )}
      <div className="md_editor_textarea">
        <MilkdownCore initialValue={initialValue} onChange={onChange} setActive={setActive} setLevel={setHeadingLevel} />
        <CodeEditor
          content={getMarkdown()}
          onChange={saveMarkdown}
          hidden={editType === 'visual'}
          setMDEditor={setMDEditor}
          setActive={setActive}
          setLevel={setHeadingLevel}
        />
      </div>
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
  buttons: PropTypes.arrayOf(PropTypes.oneOf(defaultButtons)),
};

MarkdownEditor.defaultProps = {
  buttons: defaultButtons,
  newValue: '',
};

export default MarkdownEditor;
