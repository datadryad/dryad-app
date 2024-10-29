import {editorViewOptionsCtx} from '@milkdown/core';
import 'prosemirror-view/style/prosemirror.css';
import 'prosemirror-tables/style/tables.css';
import './milkdown_editor.css';

const dryadConfig = (ctx) => {
  ctx.update(editorViewOptionsCtx, (prev) => ({
    ...prev,
    attributes: {
      class: 'milkdown dryad-milkdown-theme',
      'aria-errormessage': 'readme_error',
      'aria-labelledby': 'md_editor_label',
    },
  }));
};

export default dryadConfig;
