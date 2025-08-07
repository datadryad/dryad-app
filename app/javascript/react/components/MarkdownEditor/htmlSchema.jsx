import {$nodeSchema} from '@milkdown/kit/utils';
import {htmlAttr} from '@milkdown/kit/preset/commonmark';

const htmlSchema = $nodeSchema('html', (ctx) => ({
  group: 'inline',
  inline: true,
  content: 'text*',
  code: true,
  isolating: false,
  attrs: {
    value: {
      default: '',
    },
  },
  toDOM: (node) => {
    const span = document.createElement('span');
    const attr = {
      ...ctx.get(htmlAttr.key)(node),
      'data-value': node.attrs.value,
      'data-type': 'html',
    };
    span.textContent = node.attrs.value;
    return ['span', attr, 0];
  },
  parseDOM: [{
    tag: 'span[data-type="html"]',
    getAttrs: (dom) => ({
      value: dom.dataset.value ?? '',
    }),
  }],
  parseMarkdown: {
    match: ({type}) => Boolean(type === 'html'),
    runner: (state, node, type) => {
      state.openNode(type, {value: node.value});
      if (node.value) state.addText(node.value);
      state.closeNode();
    },
  },
  toMarkdown: {
    match: (node) => node.type.name === 'html',
    runner: (state, node) => {
      state.addNode('html', undefined, node.textContent);
    },
  },
}));

export default htmlSchema;
