import React from 'react';
import {editorViewCtx} from '@milkdown/core';
import {callCommand} from '@milkdown/utils';
import {commands} from '../milkdownCommands';
import {icons, labels} from './Details';

export default function List({type, editor, active}) {
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
