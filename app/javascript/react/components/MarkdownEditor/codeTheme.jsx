import {EditorView} from '@codemirror/view';
import {HighlightStyle, syntaxHighlighting} from '@codemirror/language';
import {Tag, styleTags, tags as t} from '@lezer/highlight';

const codeMark = Tag.define();
const code = Tag.define();
const hRule = Tag.define();
const listMark = Tag.define();
const linkRef = Tag.define();
const link = Tag.define();
const linkMark = Tag.define();
const quoteMark = Tag.define();

export const markdownTags = {
  props: [
    styleTags({
      CodeMark: codeMark,
      InlineCode: code,
      HorizontalRule: hRule,
      ListMark: listMark,
      URL: linkRef,
      Link: link,
      LinkMark: linkMark,
      QuoteMark: quoteMark,
    }),
  ],
};

export const dryadBase = EditorView.theme({}, {});

export const dryadHighlightStyle = HighlightStyle.define([
  {tag: t.heading, class: 'md_th'},
  {tag: t.heading1, class: 'md_h1'},
  {tag: t.heading2, class: 'md_h2'},
  {tag: t.heading3, class: 'md_h3'},
  {tag: t.heading4, class: 'md_h4'},
  {tag: t.heading5, class: 'md_h5'},
  {tag: t.heading6, class: 'md_h6'},
  {tag: t.emphasis, class: 'md_em'},
  {tag: t.strong, class: 'md_b'},
  {tag: t.strikethrough, class: 'md_strike'},
  {tag: codeMark, class: 'md_cmark'},
  {tag: code, class: 'md_mono'},
  {tag: t.monospace, class: 'md_code'},
  {tag: quoteMark, class: 'md_bq'},
  {tag: t.quote, class: 'md_quote'},
  {tag: t.list, class: 'md_li'},
  {tag: listMark, class: 'md_list'},
  {tag: linkRef, class: 'md_href'},
  {tag: link, class: 'md_a'},
  {tag: linkMark, class: 'md_amark'},
  {tag: hRule, class: 'md_hr'},
]);

export const dryadTheme = [dryadBase, syntaxHighlighting(dryadHighlightStyle)];
