import React, {useRef, useEffect} from 'react';
import {Editor} from '@toast-ui/react-editor';
import subsubPlugin from '../../lib/subsup_plugin';

import '@toast-ui/editor/dist/toastui-editor.css';
import '../../lib/toastui-editor.css';

export default function ReadMe({readmeUrl}) {
  const editorRef = useRef();

  useEffect(async () => {
    if (readmeUrl) {
      const response = await fetch(readmeUrl);
      const value = await response.text();
      editorRef.current.getInstance().setMarkdown(value);
    }
  }, [readmeUrl]);

  return (
    <Editor
      ref={editorRef}
      initialEditType="wysiwyg"
      height="800px"
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
