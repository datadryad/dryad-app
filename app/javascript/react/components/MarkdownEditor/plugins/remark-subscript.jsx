import {$remark} from '@milkdown/utils';
import {visit} from 'unist-util-visit';
import {subscript} from './micromark-extensions';

function add(data, field, value) {
  const list = (data[field] || []);
  if (Array.isArray(value)) {
    value.forEach((v) => {
      if (!list.includes(v)) list.push(v);
    });
  } else if (!list.includes(value)) list.push(value);
}

function handleSub(node, _, state, info) {
  const tracker = state.createTracker(info);
  const exit = state.enter('subscript');
  let value = tracker.move('~');
  value += state.containerPhrasing(node, {
    ...tracker.current(),
    before: value,
    after: '~',
  });
  value += tracker.move('~');
  exit();
  return value;
}

handleSub.peek = () => '~';

const fullPhrasingSpans = [
  'autolink',
  'destinationLiteral',
  'destinationRaw',
  'reference',
  'titleQuote',
  'titleApostrophe',
];

const subToMarkdown = {
  unsafe: [
    {
      character: '~',
      inConstruct: 'phrasing',
      notInConstruct: fullPhrasingSpans,
    },
  ],
  handlers: {subscript: handleSub},
};

function enterSubscript(token) {
  this.enter({type: 'subscript', children: []}, token);
}

function exitSubscript(token) {
  this.exit(token);
}

const subFromMarkdown = {
  canContainEols: ['subscript'],
  enter: {subscript: enterSubscript},
  exit: {subscript: exitSubscript},
};

function remarkSubscript() {
  const data = this.data();
  add(data, 'micromarkExtensions', subscript());
  add(data, 'fromMarkdownExtensions', subFromMarkdown);
  add(data, 'toMarkdownExtensions', subToMarkdown);

  return (tree) => {
    visit(tree, 'subscript', (node, index, parent) => {
      if (!parent) return;
      const first = node.children[0];
      let content;
      if (first && first.type === 'text') {
        const match = /^~([^~]+)~/.exec(first.value);
        if (match) {
          [content] = match;
          first.value = first.value.slice(match[0].length);
          if (first.value.length === 0) {
            node.children.shift();
          }
        }
      }
      node.type = 'subscript';
      if (content) {
        node.data = {...node.data, content};
      }
      parent.children[index] = node;
    });
  };
}

const subPlugin = $remark('subscript', () => remarkSubscript);

export default subPlugin;
