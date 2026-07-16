import React, {useState, useEffect} from 'react';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {commands} from './milkdownCommands';
import {commands as mdCommands} from './codeKeymap';
/* eslint-disable-next-line import/no-cycle */
import {
  Table, Heading, ImageMenu, LinkMenu, ListMenu, List, icons, labels,
} from './Buttons';

function Button({
  type, activeDOM, editorId, activeEditor, editor, mdEditor, headingLevel,
}) {
  const [active, setActive] = useState(false);
  const [disabled, setDisabled] = useState(false);
  const sharedProps = {
    editorId, active, editor, mdEditor, activeEditor,
  };

  useEffect(() => {
    if (activeDOM?.length) {
      const activeList = activeDOM.some((a) => a && a.includes('_list'));
      setActive(
        activeDOM.includes(type)
        || (type === 'list_menu' && activeList)
        || (activeEditor === 'markdown' && type.includes('list') && activeList),
      );
      setDisabled(
        (activeEditor === 'markdown' && type === 'image')
        || (type.includes('dent') && !activeList)
        || (activeEditor === 'markdown' && type.includes('_list') && active),
      );
    }
  }, [activeDOM, activeEditor]);

  if (type === 'spacer') return <span className="spacer" role="separator" />;

  if (activeEditor === 'visual') {
    if (type === 'link') return <LinkMenu active={active} editor={editor} editorId={editorId} />;
    if (type === 'image') return <ImageMenu active={active} editor={editor} editorId={editorId} />;
    if (type.includes('_list')) return <List active={active} editor={editor} type={type} />;
  }

  if (type === 'list_menu') return <ListMenu {...sharedProps} activeDOM={activeDOM} />;
  if (type === 'table') return <Table {...sharedProps} />;
  if (type === 'heading') return <Heading {...sharedProps} headingLevel={headingLevel} />;

  const callEditorCommand = (e) => {
    if (e.target.hasAttribute('aria-disabled')) return;
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
      aria-pressed={active}
      aria-disabled={disabled || null}
      title={labels[type]}
      aria-label={labels[type]}
      onClick={callEditorCommand}
      tabIndex="-1"
    >{icons[type]}
    </button>
  );
}

export default Button;
