import {$command, $useKeymap} from '@milkdown/kit/utils';
import {commandsCtx} from '@milkdown/kit/core';
// eslint-disable-next-line import/no-unresolved
import {wrapInList} from '@milkdown/kit/prose/schema-list';
import {redoCommand, undoCommand} from '@milkdown/kit/plugin/history';
import {
  // toggleMark,
  toggleEmphasisCommand,
  toggleStrongCommand,
  toggleInlineCodeCommand,
  toggleLinkCommand,
  updateLinkCommand,
  wrapInBlockquoteCommand,
  wrapInHeadingCommand,
  createCodeBlockCommand,
  bulletListSchema,
  orderedListSchema,
  liftListItemCommand,
  sinkListItemCommand,
} from '@milkdown/kit/preset/commonmark';
import {
  insertTableCommand,
  toggleStrikethroughCommand,
} from '@milkdown/kit/preset/gfm';

export const bulletWrapCommand = $command('BulletListWrap', (ctx) => () => wrapInList(bulletListSchema.type(ctx)));
export const orderWrapCommand = $command('OrderedListWrap', (ctx) => () => wrapInList(orderedListSchema.type(ctx)));

export const bulletWrapKeymap = $useKeymap('bulletWrapKeymap', {
  BulletListWrap: {
    shortcuts: 'Mod-Alt-8',
    command: (ctx) => {
      const c = ctx.get(commandsCtx);
      return () => c.call(bulletWrapCommand.key);
    },
  },
});

export const orderWrapKeymap = $useKeymap('orderWrapKeymap', {
  OrderedListWrap: {
    shortcuts: 'Mod-Alt-7',
    command: (ctx) => {
      const c = ctx.get(commandsCtx);
      return () => c.call(orderWrapCommand.key);
    },
  },
});

export const commands = {
  undo: undoCommand,
  redo: redoCommand,
  strong: toggleStrongCommand,
  emphasis: toggleEmphasisCommand,
  inlineCode: toggleInlineCodeCommand,
  strike_through: toggleStrikethroughCommand,
  bullet_list: bulletWrapCommand,
  ordered_list: orderWrapCommand,
  outdent: liftListItemCommand,
  indent: sinkListItemCommand,
  blockquote: wrapInBlockquoteCommand,
  code_block: createCodeBlockCommand,
  table: insertTableCommand,
  heading: wrapInHeadingCommand,
  link: toggleLinkCommand,
  linkEdit: updateLinkCommand,
};
