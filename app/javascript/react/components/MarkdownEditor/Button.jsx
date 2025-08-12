import React, {useState, useEffect} from 'react';
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

function ListMenu({active, editorId, ...props}) {
  const list_buttons = ['bullet_list', 'ordered_list', 'indent', 'outdent'];

  const closeMenu = () => {
    const menu = document.getElementById(`${editorId}listMenu`);
    menu.previousElementSibling.setAttribute('aria-expanded', false);
    menu.previousElementSibling.lastElementChild.classList.add('fa-chevron-down');
    menu.previousElementSibling.lastElementChild.classList.remove('fa-chevron-up');
    menu.hidden = true;
  };

  const clickListener = (e) => {
    const element = document.getElementById(`${editorId}listMenu`).parentElement;
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
      e.currentTarget.lastElementChild.classList.remove('fa-chevron-down');
      e.currentTarget.lastElementChild.classList.add('fa-chevron-up');
      document.getElementById(`${editorId}listMenu`).removeAttribute('hidden');
      document.addEventListener('click', clickListener);
    }
  };

  const leaveMenu = (e) => {
    if (e.currentTarget.contains(e.relatedTarget)) return;
    closeMenu();
  };

  return (
    <div className="listSelect" role="menuitem" onBlur={leaveMenu}>
      <button
        type="button"
        className={active ? 'active' : undefined}
        title="List options"
        aria-label="List options"
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls={`${editorId}listMenu`}
        onClick={openMenu}
      >
        <i className="fas fa-bars" aria-hidden="true" />
        <i className="fas fa-chevron-down" aria-hidden="true" />
      </button>
      <div className="listMenu" role="menu" id={`${editorId}listMenu`} hidden>
        {list_buttons.map((b) => (
          <Button key={b} type={b} editorId={editorId} {...props} />
        ))}
      </div>
    </div>
  );
}

function Button({
  type, activeDOM, editorId, activeEditor, editor, mdEditor, headingLevel,
}) {
  const [active, setActive] = useState(false);
  const [disabled, setDisabled] = useState(false);

  useEffect(() => {
    if (activeDOM?.length) {
      const activeList = activeDOM.some((a) => a && a.includes('_list'));
      setActive(
        activeDOM.includes(type)
        || (type === 'list_menu' && activeList)
        || (activeEditor === 'markdown' && type.includes('list') && activeList),
      );
      setDisabled(
        (type.includes('dent') && !activeList)
        || (activeEditor === 'markdown' && type.includes('_list') && active),
      );
    }
  }, [activeDOM, activeEditor]);

  if (type === 'spacer') return <span className="spacer" role="separator" />;
  if (activeEditor === 'visual') {
    if (type === 'link') return <LinkMenu active={active} editor={editor} editorId={editorId} />;
    if (type.includes('_list')) return <List active={active} editor={editor} type={type} />;
    if (['strong', 'emphasis', 'inlineCode', 'strike_through'].includes(type)) {
      return <Toggle active={active} editor={editor} type={type} disabled={disabled} />;
    }
  }
  const sharedProps = {
    editorId, active, editor, mdEditor, activeEditor,
  };
  if (type === 'list_menu') return <ListMenu {...sharedProps} activeDOM={activeDOM} />;
  if (type === 'table') return <Table {...sharedProps} />;
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
      disabled={disabled}
      title={labels[type]}
      aria-label={labels[type]}
      role="menuitem"
      onClick={callEditorCommand}
    >{icons[type]}
    </button>
  );
}

export default Button;
