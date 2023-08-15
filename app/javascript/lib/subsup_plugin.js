import {toggleMark} from 'prosemirror-commands';
import './subsup_plugin.css';

function createTextSelection(tr, SelectionClass, from, to) {
  const end = to || from;
  const contentSize = tr.doc.content.size;
  const size = contentSize > 0 ? contentSize - 1 : 1;
  return SelectionClass.create(tr.doc, Math.min(from, size), Math.min(end, size));
}

export default function supsubPlugin(context) {
  const {eventEmitter, pmState} = context;
  let currentEditorEl = null;

  eventEmitter.listen('focus', () => {
    currentEditorEl = document.activeElement;
  });

  eventEmitter.listen('command', (command) => {
    if (['superscript', 'subscript'].includes(command)) currentEditorEl.focus();
  });

  eventEmitter.listen('caretChange', (editType) => {
    const editor = currentEditorEl?.closest('.toastui-editor-defaultUI');
    const sel = window.getSelection();
    const checkNode = editType === 'markdown'
      ? sel.anchorNode?.previousSibling?.innerText.replace(/[^\w\s]/gi, '')
      : sel.anchorNode?.parentNode?.localName;
    const supButton = editor?.querySelector('button.superscript');
    const subButton = editor?.querySelector('button.subscript');
    if (checkNode && checkNode === 'sup') {
      supButton.classList.add('active');
    } else if (supButton?.classList.contains('active')) {
      supButton.classList.remove('active');
    }
    if (checkNode && checkNode === 'sub') {
      subButton.classList.add('active');
    } else if (subButton?.classList.contains('active')) {
      subButton.classList.remove('active');
    }
  });

  function toggleMD({openTag, closeTag}, {tr, selection}, dispatch) {
    const reSubSup = new RegExp(`^${openTag}.*([sS]*)</su(p|b)>$`, 'm');
    function conditionFn(text) { return reSubSup.test(text); }
    const syntaxLen = openTag.length;
    const endLen = closeTag.length;
    const {doc} = tr;
    const {from, to} = selection;
    const prevPos = Math.max(from - syntaxLen, 1);
    const nextPos = Math.min(to + endLen, doc.content.size - 1);
    const slice = selection.content();
    let textContent = slice.content.textBetween(0, slice.content.size, '\n');
    const prevText = doc.textBetween(prevPos, from, '\n');
    const nextText = doc.textBetween(to, nextPos, '\n');
    textContent = `${prevText}${textContent}${nextText}`;
    if (prevText && nextText && conditionFn(textContent)) {
      tr.delete(nextPos - endLen, nextPos).delete(prevPos, prevPos + syntaxLen);
    } else {
      tr.insertText(closeTag, to).insertText(openTag, from);
      const newSelection = selection.empty
        ? createTextSelection(tr, pmState.TextSelection, from + syntaxLen)
        : createTextSelection(tr, pmState.TextSelection, from + syntaxLen, to + syntaxLen);
      tr.setSelection(newSelection);
    }
    dispatch(tr);
    return true;
  }

  const subButton = {
    name: 'subscript',
    tooltip: 'Subscript',
    command: 'subscript',
    className: 'subscript toastui-editor-toolbar-icons',
  };

  const superButton = {
    name: 'superscript',
    tooltip: 'Superscript',
    command: 'superscript',
    className: 'superscript toastui-editor-toolbar-icons',
  };

  return {
    markdownCommands: {
      subscript: (_payload, state, dispatch) => {
        const tags = {openTag: '<sub>', closeTag: '</sub>'};
        return toggleMD(tags, state, dispatch);
      },
      superscript: (_payload, state, dispatch) => {
        const tags = {openTag: '<sup>', closeTag: '</sup>'};
        return toggleMD(tags, state, dispatch);
      },
    },
    wysiwygCommands: {
      subscript: (_payload, state, dispatch) => toggleMark(state.schema.marks.sub)(state, dispatch),
      superscript: (_payload, state, dispatch) => toggleMark(state.schema.marks.sup)(state, dispatch),
    },
    toolbarItems: [
      {
        groupIndex: 0,
        itemIndex: 4,
        item: subButton,
      },
      {
        groupIndex: 0,
        itemIndex: 5,
        item: superButton,
      },
    ],
    toHTMLRenderers: {
      htmlInline: {
        sub(node, {entering}) {
          return entering
            ? {type: 'openTag', tagName: 'sub'}
            : {type: 'closeTag', tagName: 'sub'};
        },
        sup(node, {entering}) {
          return entering
            ? {type: 'openTag', tagName: 'sup'}
            : {type: 'closeTag', tagName: 'sup'};
        },
      },
    },
  };
}
