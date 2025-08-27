import {$command, $useKeymap} from '@milkdown/kit/utils';
import {commandsCtx} from '@milkdown/kit/core';
import {wrapInList} from '@milkdown/kit/prose/schema-list';
import {redoCommand, undoCommand} from '@milkdown/kit/plugin/history';
import {toggleMark} from '@milkdown/kit/prose/commands';
import {
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
import {supSchema, subSchema} from './schemas';

export const bulletWrapCommand = $command('BulletListWrap', (ctx) => () => wrapInList(bulletListSchema.type(ctx)));
export const orderWrapCommand = $command('OrderedListWrap', (ctx) => () => wrapInList(orderedListSchema.type(ctx)));
export const toggleSupCommand = $command('ToggleSup', (ctx) => () => toggleMark(supSchema.type(ctx)));
export const toggleSubCommand = $command('ToggleSub', (ctx) => () => toggleMark(subSchema.type(ctx)));

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

export const supKeymap = $useKeymap('supKeymap', {
  ToggleSup: {
    shortcuts: 'Mod-Alt-Shift-=',
    command: (ctx) => {
      const c = ctx.get(commandsCtx);
      return () => c.call(toggleSupCommand.key);
    },
  },
});

export const subKeymap = $useKeymap('subKeymap', {
  ToggleSub: {
    shortcuts: 'Mod-Alt-=',
    command: (ctx) => {
      const c = ctx.get(commandsCtx);
      return () => c.call(toggleSubCommand.key);
    },
  },
});

export const noNewLines = $command('NoNewLines', () => () => () => true);

export const exitKeymap = $useKeymap('exitKeyMap', {
  CustomCommand: {
    shortcuts: ['Enter', 'Shift-Enter', 'Mod-b', 'Mod-e', 'Mod-k', 'Mod-Alt-x', 'Mod-Shift-b', 'Mod-Alt-7', 'Mod-Alt-8', 'Mod-]', 'Mod-['],
    priority: 100,
    command: (ctx) => {
      const c = ctx.get(commandsCtx);
      return () => c.call(noNewLines.key);
    },
  },
});

export const commands = {
  undo: undoCommand,
  redo: redoCommand,
  strong: toggleStrongCommand,
  emphasis: toggleEmphasisCommand,
  superscript: toggleSupCommand,
  subscript: toggleSubCommand,
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
