import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
// import {Field, Form, Formik} from 'formik';
import {Editor} from '@tinymce/tinymce-react';
import {showSavedMsg, showSavingMsg} from "../../../lib/utils";
import axios from "axios";

export default function RichText({dcsDescription, path, mceKey, mceLabel}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const editorRef = useRef(null);

  const submit = () => {
    if (editorRef.current) {
      const subJson = {
        'authenticity_token': csrf,
        description: {
          description: editorRef.current.getContent(),
          resource_id: dcsDescription.resource_id,
          id: dcsDescription.id
        }
      }
      showSavingMsg();
      axios.patch(path, subJson, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
          .then((data) => {
            if (data.status !== 200) {
              console.log('Response failure not a 200 response');
            }
            showSavedMsg();
          });
      console.log(subJson);
    }
  };

  // remove registration nag https://medium.com/@petehouston/remove-tinymce-warning-notification-on-cloud-api-key-70a4a352b8b0

  return (
      <div style={{width: '100%'}}>
        <label htmlFor="description" className="c-input__label required" id="abstract_label">
          Abstract
        </label>
        <>{mceLabel.describe}</>
        <Editor
            onInit={(evt, editor) => editorRef.current = editor}
            apiKey={mceKey}
            initialValue={dcsDescription.description}
            init={{
              height: 300,
              width: '100%',
              menubar: false,
              plugins: [
                'advlist anchor autolink charmap code directionality hr help lists link table textcolor'
              ],
              toolbar: 'help | formatselect | ' +
                  'bold italic strikethrough forecolor backcolor removeformat | alignleft aligncenter ' +
                  'alignright | bullist numlist outdent indent | ' +
                  'table link hr blockquote | superscript subscript charmap | undo redo | fontsizeselect | ltr rtl ',
              table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | ' +
                  'tableinsertcolbefore tableinsertcolafter tabledeletecol',
              content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }',
              branding: false
            }}
            onBlur={ (e) => { submit(); } }
        />
        <br/>
      </div>
  );
}