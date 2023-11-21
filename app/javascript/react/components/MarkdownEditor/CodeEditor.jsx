import React, {useRef, useState, useEffect} from 'react';
import {isEqual} from 'lodash';
import {
  autocompletion, closeBrackets, closeBracketsKeymap, completionKeymap,
} from '@codemirror/autocomplete';
import {defaultKeymap, history, historyKeymap} from '@codemirror/commands';
import {
  bracketMatching, defaultHighlightStyle, indentOnInput, syntaxHighlighting,
} from '@codemirror/language';
import {lintKeymap} from '@codemirror/lint';
import {searchKeymap} from '@codemirror/search';
import {EditorState, Prec} from '@codemirror/state';
import {EditorView, highlightSpecialChars, keymap} from '@codemirror/view';
import {markdown, markdownLanguage} from '@codemirror/lang-markdown';
import {dryadTheme, markdownTags} from './codeTheme';
import {codeKeymap} from './codeKeymap';

const basicSetup = [
  highlightSpecialChars(),
  history(),
  EditorState.allowMultipleSelections.of(true),
  EditorView.lineWrapping,
  indentOnInput(),
  syntaxHighlighting(defaultHighlightStyle, {fallback: true}),
  bracketMatching(),
  closeBrackets(),
  autocompletion(),
  keymap.of([
    ...closeBracketsKeymap,
    ...defaultKeymap,
    ...searchKeymap,
    ...historyKeymap,
    ...completionKeymap,
    ...lintKeymap,
  ]),
  Prec.highest(
    keymap.of([
      ...codeKeymap,
    ]),
  ),
];

const nodeClasses = {
  md_h1: 'heading',
  md_h2: 'heading',
  md_h3: 'heading',
  md_h4: 'heading',
  md_h5: 'heading',
  md_h6: 'heading',
  md_em: 'emphasis',
  md_b: 'strong',
  md_strike: 'strike_through',
  md_cmark: 'code_block',
  md_code: 'code_block',
  md_mono: 'inlineCode',
  md_bq: 'blockquote',
  md_quote: 'blockquote',
  md_li: 'list',
  md_list: 'list',
  md_href: 'link',
  md_a: 'link',
  md_amark: 'link',
};

const headingClasses = {
  md_h1: 1,
  md_h2: 2,
  md_h3: 3,
  md_h4: 4,
  md_h5: 5,
  md_h6: 6,
};

export default function CodeEditor({
  hidden, content, onChange, setMDEditor, setActive, setLevel,
}) {
  const editor = useRef();
  const prevSelection = useRef();
  const [vw, setView] = useState();
  const [selection, setSelection] = useState();

  useEffect(() => {
    if (!isEqual(selection, prevSelection.current)) {
      prevSelection.current = selection;
      setActive([]);
      setLevel(0);
      const [range] = selection.ranges;
      const {node} = vw.domAtPos(range.from);
      const {parentElement} = node;
      if (parentElement) {
        const classes = [...parentElement.classList];
        setActive(classes.map((c) => nodeClasses[c]));
        setLevel(classes.reduce((e, c) => headingClasses[c] || e, 0));
      }
    }
  }, [selection]);

  useEffect(() => {
    const state = EditorState.create({
      doc: content,
      extensions: [
        dryadTheme,
        basicSetup,
        markdown({
          base: markdownLanguage,
          extensions: [markdownTags],
        }),
        EditorView.updateListener.of((v) => {
          if (v.docChanged) {
            onChange(v.state.doc.toString());
          }
          setSelection(v.state.selection);
        }),
      ],
    });

    const view = new EditorView({
      state,
      parent: editor.current,
    });

    setView(view);
    setMDEditor(view);

    return () => {
      view.destroy();
    };
  }, [content]);

  return (<div ref={editor} className="markdown_codemirror" hidden={hidden} />);
}
