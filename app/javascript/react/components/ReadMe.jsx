import React, {useRef} from 'react';
import {Editor} from '@toast-ui/react-editor';
import subsubPlugin from '../../lib/subsup_plugin';

import '@toast-ui/editor/dist/toastui-editor.css';

export default function ReadMe() {
  const editorRef = useRef();

  return (
    <Editor
      ref={editorRef}
      initialEditType="wysiwyg"
      height="700px"
      initialValue="# Hello World"
      toolbarItems={[
        ['heading', 'bold', 'italic', 'strike'],
        ['hr', 'quote', 'link'],
        ['ul', 'ol', 'indent', 'outdent'],
        ['table', 'code', 'codeblock'],
      ]}
      plugins={[subsubPlugin]}
      useCommandShortcut
    />
  );
}
