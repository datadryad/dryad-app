import {splice} from 'micromark-util-chunked';
import {classifyCharacter} from 'micromark-util-classify-character';
import {resolveAll} from 'micromark-util-resolve-all';
import {codes, constants, types} from 'micromark-util-symbol';

/* eslint-disable no-plusplus, no-underscore-dangle */
export default function superscript() {
  function tokenizeSuperscript(effects, ok, nok) {
    const {previous} = this;
    const {events} = this;
    let size = 0;

    function more(code) {
      const before = classifyCharacter(previous);

      if (code === codes.caret) {
        // If this is the third marker, exit.
        if (size > 1) return nok(code);
        effects.consume(code);
        size++;
        return more;
      }

      const token = effects.exit('superscriptSequenceTemporary');
      const after = classifyCharacter(code);
      token._open = !after || (after === constants.attentionSideAfter && Boolean(before));
      token._close = !before || (before === constants.attentionSideAfter && Boolean(after));
      return ok(code);
    }

    function start(code) {
      if (code !== codes.caret) return 'expected `^`';

      if (
        previous === codes.caret
        && events[events.length - 1][1].type !== types.characterEscape
      ) {
        return nok(code);
      }

      effects.enter('superscriptSequenceTemporary');
      return more(code);
    }

    return start;
  }

  function resolveAllSuperscript(events, context) {
    let index = -1;

    // Walk through all events.
    while (++index < events.length) {
      // Find a token that can close.
      if (
        events[index][0] === 'enter'
        && events[index][1].type === 'superscriptSequenceTemporary'
        && events[index][1]._close
      ) {
        let open = index;

        // Now walk back to find an opener.
        while (open--) {
          // Find a token that can open the closer.
          if (
            events[open][0] === 'exit'
            && events[open][1].type === 'superscriptSequenceTemporary'
            && events[open][1]._open
            // If the sizes are the same:
            && events[index][1].end.offset - events[index][1].start.offset
              === events[open][1].end.offset - events[open][1].start.offset
          ) {
            events[index][1].type = 'superscriptSequence';
            events[open][1].type = 'superscriptSequence';

            const sup = {
              type: 'superscript',
              start: {...events[open][1].start},
              end: {...events[index][1].end},
            };
            const text = {
              type: 'superscriptText',
              start: {...events[open][1].end},
              end: {...events[index][1].start},
            };

            // Opening.
            const nextEvents = [
              ['enter', sup, context],
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
              ['exit', sup, context],
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
      if (events[index][1].type === 'superscriptSequenceTemporary') {
        events[index][1].type = types.data;
      }
    }

    return events;
  }

  const tokenizer = {
    name: 'superscript',
    tokenize: tokenizeSuperscript,
    resolveAll: resolveAllSuperscript,
  };

  return {
    text: {[codes.caret]: tokenizer},
    insideSpan: {null: [tokenizer]},
    attentionMarkers: {null: [codes.caret]},
  };
}

export function superscriptHtml() {
  return {
    enter: {
      superscript() {
        this.tag('<sup>');
      },
    },
    exit: {
      superscript() {
        this.tag('</sup>');
      },
    },
  };
}
