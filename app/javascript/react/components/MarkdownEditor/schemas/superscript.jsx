import {markRule} from '@milkdown/prose';
import {$inputRule, $markAttr, $markSchema} from '@milkdown/utils';

export const supAttr = $markAttr('superscript');

export const supSchema = $markSchema('superscript', (ctx) => ({
  priority: 100,
  attrs: {
    marker: {
      default: '^',
      validate: 'string',
    },
  },
  parseDOM: [{tag: 'sup'}],
  toDOM: (mark) => ['sup', ctx.get(supAttr.key)(mark)],
  parseMarkdown: {
    match: (node) => node.type === 'superscript',
    runner: (state, node, markType) => {
      state.openMark(markType, {marker: node.marker});
      state.next(node.children);
      state.closeMark(markType);
    },
  },
  toMarkdown: {
    match: (mark) => mark.type.name === 'superscript',
    runner: (state, mark) => {
      state.withMark(mark, 'superscript', undefined, {
        marker: mark.attrs.marker,
      });
    },
  },
}));

export const supRule = $inputRule((ctx) => markRule(/(?:\^)([^^]+)(?:\^)/, supSchema.type(ctx)));
