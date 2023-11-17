import {EditorSelection, Text, Transaction} from '@codemirror/state';

const marks = {
  // marks
  strong: '\\*\\*',
  emphasis: '\\*',
  inlineCode: '`',
  strike_through: '~~',
  // nodes
  blockquote: '> ',
  bullet_list: '* ',
  indent: '    ',
  heading: '#',
  code_block: '```',
};

const classes = {
  strong: 'md_b',
  emphasis: 'md_em',
  inlineCode: 'md_mono',
  strike_through: 'md_strike',
};

const closest = (el, selector) => {
  let m = el;
  while (m) {
    if (m.matches && m.matches(selector)) {
      break;
    }
    m = m.parentElement;
  }
  return m;
};

const toggleMark = (mark, classMarker, view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    const changeList = [];
    const {node} = view.domAtPos(range.from);
    const {data, parentElement} = node;
    const markString = mark.replace(/\\/g, '');
    const hasClass = parentElement.classList.contains(classMarker);
    const isMarkBefore = state.sliceDoc(range.from - markString.length, range.from) === markString;
    const isMarkAfter = state.sliceDoc(range.to, range.to + markString.length) === markString;
    if (hasClass) {
      const r = new RegExp(`^${mark}`);
      const x = new RegExp(`${mark}$`);
      let newString = data.replace(r, '');
      newString = newString.replace(x, '');
      const start = view.posAtDOM(parentElement);
      changeList.push({
        from: start,
        to: start + data.length,
        insert: newString,
      });
    } else if (isMarkBefore && isMarkAfter) {
      changeList.push({
        from: range.from - markString.length,
        to: range.from,
        insert: Text.of(['']),
      }, {
        from: range.to,
        to: range.to + markString.length,
        insert: Text.of(['']),
      });
    } else {
      changeList.push({
        from: range.from,
        insert: Text.of([markString]),
      }, {
        from: range.to,
        insert: Text.of([markString]),
      });
    }
    const extend = (hasClass || (isMarkBefore && isMarkAfter)) ? -markString.length : markString.length;
    return {
      changes: changeList,
      range: EditorSelection.range(range.from + extend, range.to + extend),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const insertLink = (view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    let start = range.from;
    let end = range.to;
    const changeList = [];
    const {node} = view.domAtPos(range.from);
    const {parentElement} = node;
    const hasClass = ['md_a', 'md_amark', 'md_href'].some((className) => parentElement.classList.contains(className));
    if (hasClass) {
      changeList.push({});
    } else {
      changeList.push({
        from: range.from,
        insert: Text.of(['[']),
      }, {
        from: range.to,
        insert: Text.of([']()']),
      });
      start = range.to + 3;
      end = range.to + 3;
    }
    return {
      changes: changeList,
      range: EditorSelection.range(start, end),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const nodeWrap = (mark, view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    const changeList = [];
    let extend = 0; let extEnd = 0;
    const string = state.sliceDoc(range.from, range.to);
    const {text: lineArr} = state.toText(string);
    const realCount = lineArr.filter((l) => l.length > 0).length;
    const {node} = view.domAtPos(range.from);
    const line = closest(node, '.cm-line');
    const start = view.posAtDOM(line);
    if (realCount === 0) {
      changeList.push({
        from: start,
        insert: Text.of([mark]),
      });
      extend = mark.length;
    } else {
      const editedArray = lineArr.reduce((a, l) => {
        if (l.length) {
          const n = `${mark} ${l}`;
          a.push(n);
        } else {
          a.push(l);
        }
        return a;
      }, []);
      const editedString = editedArray.join('\r');
      changeList.push({
        from: start,
        to: range.to,
        insert: editedString,
      });
      extEnd = editedString.length - string.length;
    }
    return {
      changes: changeList,
      range: EditorSelection.range(range.from + extend, range.to + extEnd),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const nodeUnwrap = (mark, view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    const changeList = [];
    let extend = 0; let extEnd = 0;
    const string = state.sliceDoc(range.from, range.to);
    const {text: lineArr} = state.toText(string);
    const realCount = lineArr.filter((l) => l.length > 0).length;
    const {node} = view.domAtPos(range.from);
    const line = closest(node, '.cm-line');
    const start = view.posAtDOM(line);
    const r = new RegExp(`^${mark} *`);
    if (realCount === 0) {
      const remove = line.innerText.replace(r, '');
      const chars = line.innerText.length - remove.length;
      changeList.push({
        from: start,
        to: start + chars,
        insert: Text.of(['']),
      });
      extend = -chars; extEnd = -chars;
    } else {
      const editedArray = lineArr.reduce((a, l) => {
        if (l.length) {
          const n = l.replace(r, '');
          a.push(n);
        } else {
          a.push(l);
        }
        return a;
      }, []);
      const editedString = editedArray.join('\r');
      changeList.push({
        from: start,
        to: range.to,
        insert: editedString,
      });
      extEnd = editedString.length - string.length;
    }
    return {
      changes: changeList,
      range: EditorSelection.range(range.from + extend, range.to + extEnd),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const numberWrap = (view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    const changeList = [];
    let extend = 0; let extEnd = 3;
    const string = state.sliceDoc(range.from, range.to);
    const {text: lineArr} = state.toText(string);
    const realCount = lineArr.filter((l) => l.length > 0).length;
    const {node} = view.domAtPos(range.from);
    const line = closest(node, '.cm-line');
    const start = view.posAtDOM(line);
    if (realCount === 0) {
      changeList.push({
        from: start,
        insert: Text.of['1. '],
      });
      extend = 3;
    } else {
      const editedArray = lineArr.reduce((a, l) => {
        if (l.length) {
          const n = `${a.filter((li) => li.length).length + 1}. ${l}`;
          a.push(n);
        } else {
          a.push(l);
        }
        return a;
      }, []);
      const editedString = editedArray.join('\r');
      changeList.push({
        from: start,
        to: range.to,
        insert: editedString,
      });
      extEnd = editedString.length - string.length;
    }
    return {
      changes: changeList,
      range: EditorSelection.range(range.from + extend, range.to + extEnd),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const headingWrap = (mark, view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    const changeList = [];
    const markString = `${mark.replace(/\\/g, '')} `;
    const r = new RegExp(`^${marks.heading}+ *`);
    const {node} = view.domAtPos(range.from);
    const line = closest(node, '.cm-line');
    const remove = line.innerText.replace(r, '');
    const chars = line.innerText.length - remove.length;
    const start = view.posAtDOM(line);
    if (chars) {
      changeList.push({
        from: start,
        to: start + chars,
        insert: Text.of(['']),
      });
    }
    if (mark) {
      changeList.push({
        from: start,
        insert: Text.of([markString]),
      });
    }
    const extend = mark ? markString.length - chars : -chars;
    return {
      changes: changeList,
      range: EditorSelection.range(range.from + extend, range.to + extend),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const codeBlockWrap = (mark, view) => {
  const {state, dispatch} = view;
  const changes = state.changeByRange((range) => {
    const changeList = [];
    const {node} = view.domAtPos(range.from);
    const line = closest(node, '.cm-line');
    const start = view.posAtDOM(line);
    changeList.push({
      from: start,
      insert: `${mark}\r`,
    }, {
      from: range.to,
      insert: `\r${mark}`,
    });
    return {
      changes: changeList,
      range: EditorSelection.range(range.from + mark.length + 1, range.to + mark.length + 1),
    };
  });
  dispatch(
    state.update(changes, {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of('input'),
    }),
  );
  return true;
};

const inListCheck = (view) => {
  const [range] = view.state.selection.ranges;
  const {node} = view.domAtPos(range.from);
  const line = closest(node, '.cm-line');

  return !!line.querySelector('.md_li');
};

const headingLevels = [0, 1, 2, 3, 4, 5, 6];

const headingCommands = headingLevels.reduce((o, l) => ({
  ...o,
  [`heading${l}`]: (v) => headingWrap(marks.heading.repeat(l), v),
}), {});

export const commands = {
  strong: (v) => toggleMark(marks.strong, classes.strong, v),
  emphasis: (v) => toggleMark(marks.emphasis, classes.emphasis, v),
  inlineCode: (v) => toggleMark(marks.inlineCode, classes.inlineCode, v),
  strike_through: (v) => toggleMark(marks.strike_through, classes.strike_through, v),
  link: (v) => insertLink(v),
  blockquote: (v) => nodeWrap(marks.blockquote, v),
  code_block: (v) => codeBlockWrap(marks.code_block, v),
  ordered_list: (v) => !inListCheck(v) && numberWrap(v),
  bullet_list: (v) => !inListCheck(v) && nodeWrap(marks.bullet_list, v),
  indent: (v) => inListCheck(v) && nodeWrap(marks.indent, v),
  outdent: (v) => nodeUnwrap(marks.indent, v),
  ...headingCommands,
};

const headingMap = headingLevels.map((l) => ({key: `Mod-Alt-${l}`, run: commands[`heading${l}`]}));

export const codeKeymap = [
  {
    key: 'Mod-b',
    run: commands.strong,
  },
  {
    key: 'Mod-i',
    run: commands.emphasis,
  },
  {
    key: 'Mod-e',
    run: commands.inlineCode,
  },
  {
    key: 'Mod-k',
    run: commands.link,
  },
  {
    key: 'Mod-Alt-x',
    run: commands.strike_through,
  },
  {
    key: 'Mod-Shift-b',
    run: commands.blockquote,
  },
  {
    key: 'Mod-Alt-c',
    run: commands.code_block,
  },
  {
    key: 'Mod-Alt-7',
    run: commands.ordered_list,
  },
  {
    key: 'Mod-Alt-8',
    run: commands.bullet_list,
  },
  {
    key: 'Mod-]',
    run: commands.indent,
  },
  {
    key: 'Mod-[',
    run: commands.outdent,
  },
  ...headingMap,
];
