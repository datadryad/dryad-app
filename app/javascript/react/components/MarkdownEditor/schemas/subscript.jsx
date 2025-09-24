import {markRule} from '@milkdown/prose';
import {$inputRule, $markAttr, $markSchema} from '@milkdown/utils';

export const subAttr = $markAttr('subscript');

export const subSchema = $markSchema('subscript', (ctx) => ({
  priority: 100,
  attrs: {
    marker: {
      default: '~',
      validate: 'string',
    },
  },
  parseDOM: [{tag: 'sub'}],
  toDOM: (mark) => ['sub', ctx.get(subAttr.key)(mark)],
  parseMarkdown: {
    match: (node) => node.type === 'subscript',
    runner: (state, node, markType) => {
      state.openMark(markType, {marker: node.marker});
      state.next(node.children);
      state.closeMark(markType);
    },
  },
  toMarkdown: {
    match: (mark) => mark.type.name === 'subscript',
    runner: (state, mark) => {
      state.withMark(mark, 'subscript', undefined, {
        marker: mark.attrs.marker,
      });
    },
  },
}));

export const subRule = $inputRule((ctx) => markRule(/(?:~)([^~]+)(?:~)/, subSchema.type(ctx)));
