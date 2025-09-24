import {splice} from 'micromark-util-chunked';
import {classifyCharacter} from 'micromark-util-classify-character';
import {resolveAll} from 'micromark-util-resolve-all';
import {codes, constants, types} from 'micromark-util-symbol';

/* eslint-disable no-plusplus, no-underscore-dangle */
const movePoint = (point, offset) => {
  point.column += offset;
  point.offset += offset;
  point._bufferIndex += offset;
};

export default function subscript() {
  function tokenizeSubscript(effects, ok, nok) {
    const {previous} = this;
    const {events} = this;
    let size = 0;

    function more(code) {
      const before = classifyCharacter(previous);

      if (code === codes.tilde) {
        // If this is the third marker, exit.
        if (size > 1) return nok(code);
        effects.consume(code);
        size++;
        return more;
      }

      const token = effects.exit('subscriptSequenceTemporary');
      const after = classifyCharacter(code);
      token._open = !after || (after === constants.attentionSideAfter && Boolean(before));
      token._close = !before || (before === constants.attentionSideAfter && Boolean(after));
      return ok(code);
    }

    function start(code) {
      if (code !== codes.tilde) return 'expected `~`';

      if (
        previous === codes.tilde
        && events[events.length - 1][1].type !== types.characterEscape
      ) {
        return nok(code);
      }

      effects.enter('subscriptSequenceTemporary');
      return more(code);
    }

    return start;
  }

  function resolveAllSubscript(events, context) {
    let index = -1;

    // Walk through all events.
    while (++index < events.length) {
      // Find a token that can close.
      if (
        events[index][0] === 'enter'
        && events[index][1].type === 'subscriptSequenceTemporary'
        && events[index][1]._close
      ) {
        let open = index;

        // Now walk back to find an opener.
        while (open--) {
          // Find a token that can open the closer.
          if (
            events[open][0] === 'exit'
            && events[open][1].type === 'subscriptSequenceTemporary'
            && events[open][1]._open
            // If the sizes are the same:
            && events[index][1].end.offset - events[index][1].start.offset
              === events[open][1].end.offset - events[open][1].start.offset
          ) {
            const use = events[open][1].end.offset - events[open][1].start.offset > 1
            && events[index][1].end.offset - events[index][1].start.offset > 1
              ? 2
              : 1;
            const start = {...events[open][1].end};
            const end = {...events[index][1].start};
            movePoint(start, -use);
            movePoint(end, use);

            const openingSequence = {
              type: use > 1 ? 'strikethroughSequence' : 'subscriptSequence',
              start,
              end: {...events[open][1].end},
            };
            const closingSequence = {
              type: use > 1 ? 'strikethroughSequence' : 'subscriptSequence',
              start: {...events[index][1].start},
              end,
            };

            events[open][1].end = {...openingSequence.start};
            events[index][1].start = {...closingSequence.end};

            const group = {
              type: use > 1 ? 'strikethrough' : 'subscript',
              start: {...openingSequence.start},
              end: {...closingSequence.end},
            };
            const text = {
              type: use > 1 ? 'strikethroughText' : 'subscriptText',
              start: {...events[open][1].end},
              end: {...events[index][1].start},
            };

            // Opening.
            const nextEvents = [
              ['enter', group, context],
              ['enter', events[open][1], context],
              ['exit', events[open][1], context],
              ['enter', text, context],
            ];

            const insideSpan = context.parser.constructs.insideSpan.null;

            if (insideSpan) {
              // Between.
              splice(
                nextEvents,
                nextEvents.length,
                0,
                resolveAll(insideSpan, events.slice(open + 1, index), context),
              );
            }

            // Closing.
            splice(nextEvents, nextEvents.length, 0, [
              ['exit', text, context],
              ['enter', events[index][1], context],
              ['exit', events[index][1], context],
              ['exit', group, context],
            ]);

            splice(events, open - 1, index - open + 3, nextEvents);

            index = open + nextEvents.length - 2;
            break;
          }
        }
      }
    }

    index = -1;

    while (++index < events.length) {
      if (events[index][1].type === 'subscriptSequenceTemporary') {
        events[index][1].type = types.data;
      }
    }

    return events;
  }

  const tokenizer = {
    name: 'subscript',
    tokenize: tokenizeSubscript,
    resolveAll: resolveAllSubscript,
  };

  return {
    text: {[codes.tilde]: tokenizer},
    insideSpan: {null: [tokenizer]},
    attentionMarkers: {null: [codes.tilde]},
  };
}

export function subscriptHtml() {
  return {
    enter: {
      subscript() {
        this.tag('<sub>');
      },
    },
    exit: {
      subscript() {
        this.tag('</sub>');
      },
    },
  };
}
