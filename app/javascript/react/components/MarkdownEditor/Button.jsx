import React from 'react';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {TextSelection} from '@milkdown/kit/prose/state';
import {commands} from './milkdownCommands';
import {commands as mdCommands} from './codeKeymap';
import {
  Table, Heading, LinkMenu, List, icons, labels,
} from './Buttons';

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
