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
    <>
      <h1 className="o-heading__level1">Prepare README file</h1>
      <div className="o-admin-columns">
        <div className="o-admin-left" style={{minWidth: '400px', flexGrow: 2}}>
          <p>Your Dryad submission must be accompanied by a README file, to help others use
          and understand your dataset.
          </p>
          <p>Your README should contain the details needed to interpret and reuse your data,
          including abbreviations and codes, file descriptions, and information about any necessary software.
          </p>
          <p>The editor below is pre-filled with a template to help you get started.</p>
        </div>
        <div className="o-admin-right cedar-container" style={{minWidth: '400px', flexShrink: 2}}>
          <h2 className="o-heading__level2">Already have a README file?</h2>
          <p>If you already have a markdown-formatted README file for your dataset, you can import it here.
          This will replace our template in the editor.
          </p>
        </div>
      </div>
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
    </>
  );
}
