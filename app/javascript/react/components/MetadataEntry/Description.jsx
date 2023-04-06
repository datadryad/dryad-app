import React, {useRef} from 'react';
import {Editor} from '@tinymce/tinymce-react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export default function Description({
  dcsDescription, path, mceKey, mceLabel, isCurator,
}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const editorRef = useRef(null);

  const submit = () => {
    if (editorRef.current) {
      const subJson = {
        authenticity_token: csrf,
        description: {
          description: editorRef.current.getContent(),
          resource_id: dcsDescription.resource_id,
          id: dcsDescription.id,
        },
      };
      showSavingMsg();
      axios.patch(path, subJson, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
        .then((data) => {
          if (data.status !== 200) {
            // console.log('Response failure not a 200 response');
          }
          showSavedMsg();
        });
    }
  };

  // remove registration nag https://medium.com/@petehouston/remove-tinymce-warning-notification-on-cloud-api-key-70a4a352b8b0

  return (
    <div style={{width: '100%'}}>
      <label
        className={`c-input__label ${(mceLabel.required ? 'required' : '')}`}
        id={`${dcsDescription.description_type}_label`}
        htmlFor={`editor_${dcsDescription.description_type}`}
      >
        {mceLabel.label}
      </label>
      {mceLabel.describe}
      <Editor
        id={`editor_${dcsDescription.description_type}`}
        onInit={(evt, editor) => { editorRef.current = editor; }}
        apiKey={mceKey}
        initialValue={dcsDescription.description}
        init={{
          height: 300,
          width: '100%',
          menubar: false,
          plugins: 'advlist anchor autolink charmap code directionality help lists link table',
          toolbar: 'help | blocks | '
                  + 'bold italic strikethrough forecolor backcolor removeformat | alignleft aligncenter '
                  + 'alignright | bullist numlist outdent indent | '
                  + 'table link hr blockquote | superscript subscript charmap | undo redo | fontsize | ltr rtl '
                  + `${(isCurator ? 'code' : '')}`,
          table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | '
                  + 'tableinsertcolbefore tableinsertcolafter tabledeletecol',
          content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }',
          branding: false,
        }}
        onBlur={() => { submit(); }}
      />
      <p>Press Alt 0 or Option 0 for help using the rich text editor with keyboard only.</p>
    </div>
  );
}

Description.propTypes = {
  dcsDescription: PropTypes.object.isRequired,
  path: PropTypes.string.isRequired,
  mceKey: PropTypes.string.isRequired,
  mceLabel: PropTypes.object.isRequired,
  isCurator: PropTypes.bool.isRequired,
};
