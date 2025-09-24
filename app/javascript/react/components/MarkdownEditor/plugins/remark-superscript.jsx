import {$remark} from '@milkdown/utils';
import {visit} from 'unist-util-visit';
import {superscript} from './micromark-extensions';

function add(data, field, value) {
  const list = (data[field] || []);
  if (Array.isArray(value)) {
    value.forEach((v) => {
      if (!list.includes(v)) list.push(v);
    });
  } else if (!list.includes(value)) list.push(value);
}

function handleSup(node, _, state, info) {
  const tracker = state.createTracker(info);
  const exit = state.enter('superscript');
  let value = tracker.move('^');
  value += state.containerPhrasing(node, {
    ...tracker.current(),
    before: value,
    after: '^',
  });
  value += tracker.move('^');
  exit();
  return value;
}

handleSup.peek = () => '^';

const fullPhrasingSpans = [
  'autolink',
  'destinationLiteral',
  'destinationRaw',
  'reference',
  'titleQuote',
  'titleApostrophe',
];

const supToMarkdown = {
  unsafe: [
    {
      character: '^',
      inConstruct: 'phrasing',
      notInConstruct: fullPhrasingSpans,
    },
  ],
  handlers: {superscript: handleSup},
};

function enterSuperscript(token) {
  this.enter({type: 'superscript', children: []}, token);
}

function exitSuperscript(token) {
  this.exit(token);
}

const supFromMarkdown = {
  canContainEols: ['superscript'],
  enter: {superscript: enterSuperscript},
  exit: {superscript: exitSuperscript},
};

function remarkSuperscript() {
  const data = this.data();
  add(data, 'micromarkExtensions', superscript());
  add(data, 'fromMarkdownExtensions', supFromMarkdown);
  add(data, 'toMarkdownExtensions', supToMarkdown);

  return (tree) => {
    visit(tree, 'superscript', (node, index, parent) => {
      if (!parent) return;
      const first = node.children[0];
      let content;
      if (first && first.type === 'text') {
        const match = /^\^([^^]+)\^/.exec(first.value);
        if (match) {
          [content] = match;
          first.value = first.value.slice(match[0].length);
          if (first.value.length === 0) {
            node.children.shift();
          }
        }
      }
      node.type = 'superscript';
      if (content) {
        node.data = {...node.data, content};
      }
      parent.children[index] = node;
    });
  };
}

const supPlugin = $remark('superscript', () => remarkSuperscript);

export default supPlugin;
