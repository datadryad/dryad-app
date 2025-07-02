import {EXIT, visit} from 'unist-util-visit';
import {toString} from 'mdast-util-to-string';

function formatHeadingAsSetext(node, state) {
  let literalWithBreak = false;

  // Look for literals with a line break.
  // Note that this also
  visit(node, (nod) => {
    if (
      ('value' in nod && /\r?\n|\r/.test(nod.value))
      || nod.type === 'break'
    ) {
      literalWithBreak = true;
      return EXIT;
    }
    return null;
  });

  return Boolean(
    (!node.depth || node.depth < 3)
      && toString(node)
      && (state.options.setext || literalWithBreak),
  );
}

function encodeCharacterReference(code) {
  return `&#x${code.toString(16).toUpperCase()};`;
}

function heading(node, _, state, info) {
  const rank = Math.max(Math.min(6, node.depth || 1), 1);
  const tracker = state.createTracker(info);

  if (formatHeadingAsSetext(node, state)) {
    const exit = state.enter('headingSetext');
    // const subexit = state.enter('phrasing')
    const value = state.containerPhrasing(node, {
      ...tracker.current(),
      before: '\n',
      after: '\n',
    });
    // subexit()
    exit();

    return (
      `${value
      }\n${
        (rank === 1 ? '=' : '-').repeat(
        // The whole size…
          value.length
          // Minus the position of the character after the last EOL (or
          // 0 if there is none)…
          - (Math.max(value.lastIndexOf('\r'), value.lastIndexOf('\n')) + 1),
        )}`
    );
  }

  const sequence = '#'.repeat(rank);
  const exit = state.enter('headingAtx');
  // const subexit = state.enter('phrasing')

  // Note: for proper tracking, we should reset the output positions when there
  // is no content returned, because then the space is not output.
  // Practically, in that case, there is no content, so it doesn’t matter that
  // we’ve tracked one too many characters.
  tracker.move(`${sequence} `);

  let value = state.containerPhrasing(node, {
    before: '# ',
    after: '\n',
    ...tracker.current(),
  });

  if (/^[\t ]/.test(value)) {
    // To do: what effect has the character reference on tracking?
    value = encodeCharacterReference(value.charCodeAt(0)) + value.slice(1);
  }

  value = value ? `${sequence} ${value}` : sequence;

  if (state.options.closeAtx) {
    value += ` ${sequence}`;
  }

  // subexit()
  exit();

  return value;
}

export default heading;
