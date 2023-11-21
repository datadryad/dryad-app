import {createSlice} from '@milkdown/ctx';
// eslint-disable-next-line import/no-unresolved
import {Plugin, PluginKey} from '@milkdown/prose/state';
import {InitReady, prosePluginsCtx} from '@milkdown/core';
import {debounce} from 'lodash';

export class SelectionManager {
  selectionListeners = [];

  get listeners() {
    return {
      selection: this.selectionListeners,
    };
  }

  selection(fn) {
    this.selectionListeners.push(fn);
    return this;
  }
}

export const selectionCtx = createSlice(new SelectionManager(), 'selection-listener');

export const key = new PluginKey('MILKDOWN_SELECTION_LISTENER');

export const selectionListener = (ctx) => {
  ctx.inject(selectionCtx, new SelectionManager());

  return async () => {
    await ctx.wait(InitReady);
    const listener = ctx.get(selectionCtx);
    const {listeners} = listener;

    let prevSelection = null;

    const plugin = new Plugin({
      key,
      state: {
        init: () => {
          // do nothing
        },
        apply: (tr) => {
          if (tr.selection.eq(prevSelection)) return false;

          const handler = debounce(() => {
            const {selection, doc} = tr;
            if (listeners.selection.length > 0 && (prevSelection == null || !prevSelection.eq(selection))) {
              listeners.selection.forEach((fn) => {
                fn(ctx, selection, doc);
              });
            }
            prevSelection = tr.selection;
          }, 200);

          return handler();
        },
      },
    });

    ctx.update(prosePluginsCtx, (x) => x.concat(plugin));
  };
};
