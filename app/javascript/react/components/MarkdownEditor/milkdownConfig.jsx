import {editorViewOptionsCtx} from '@milkdown/core';
import 'prosemirror-view/style/prosemirror.css';
import 'prosemirror-tables/style/tables.css';
import './milkdown_editor.css';

const dryadConfig = (ctx, attr) => {
  ctx.update(editorViewOptionsCtx, (prev) => ({
    ...prev,
    attributes: {
      class: 'milkdown dryad-milkdown-theme',
      ...attr,
    },
  }));
};

export default dryadConfig;
