/* eslint-disable */
import React, {useRef, useEffect} from 'react';

import Editor from "@toast-ui/editor";
import "@toast-ui/editor/dist/toastui-editor.css";
import classes from './Toast.module.css';

export default function Toast(){
  const editorRef = React.useRef(null);

  React.useEffect(() => {
    const editor = new Editor({
      el: editorRef.current,
      initialEditType: "wysiwyg",
      previewStyle: "vertical",
      height: "500px",
      initialValue: "# Hello World",
    });
  }, []);

  return (
      <>
        <div>
          <div ref={editorRef} />
        </div>
      </>
  );
}