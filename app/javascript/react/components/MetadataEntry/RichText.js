import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
// import {Field, Form, Formik} from 'formik';
import {Editor} from '@tinymce/tinymce-react';

export default function RichText() {
  const editorRef = useRef(null);
  const log = () => {
    if (editorRef.current) {
      console.log(editorRef.current.getContent());
    }
  };

  // remove registration nag https://medium.com/@petehouston/remove-tinymce-warning-notification-on-cloud-api-key-70a4a352b8b0

  return (
      <div style={{width: '100%'}}>
        <Editor
            onInit={(evt, editor) => editorRef.current = editor}
            initialValue="<p>This is the initial content of the editor.</p>"
            init={{
              height: 500,
              width: '100%',
              menubar: false,
              plugins: [
                'advlist anchor autolink charmap code directionality hr help lists link table textcolor'
              ],
              // add toolbar: anchor, charmap, code, ltr, rtl, insert
              toolbar: 'undo redo | formatselect | ' +
                  'bold italic strikethrough forecolor backcolor removeformat | alignleft aligncenter ' +
                  'alignright | bullist numlist outdent indent | ' +
                  'table hr blockquote | superscript subscript charmap ltr rtl | help',
              table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | ' +
                  'tableinsertcolbefore tableinsertcolafter tabledeletecol',
              content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }'
            }}
        />
        <button onClick={log}>Log editor content</button>
      </div>
  );
}