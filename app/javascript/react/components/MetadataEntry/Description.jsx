import React, {useRef, useCallback} from 'react';
import {Editor} from '@tinymce/tinymce-react';
import axios from 'axios';
import {debounce} from 'lodash';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

/* eslint-disable no-param-reassign */
const removeStyle = (el) => {
  const b = ['bold', '700'].includes(el.style.fontWeight);
  const i = el.style.fontStyle === 'italic';
  const sup = el.style.verticalAlign === 'super';
  const sub = el.style.verticalAlign === 'sub';
  [...el.attributes].forEach((attr) => attr.name !== 'href' && el.removeAttribute(attr.name));
  if (b) {
    const strong = document.createElement('strong');
    strong.innerHTML = el.outerHTML;
    el.replaceWith(strong);
    el = strong;
  }
  if (i) {
    const em = document.createElement('em');
    em.innerHTML = el.outerHTML;
    el.replaceWith(em);
    el = em;
  }
  if (sup) {
    const supEl = document.createElement('sup');
    supEl.innerHTML = el.outerHTML;
    el.replaceWith(supEl);
  } else if (sub) {
    const subEl = document.createElement('sub');
    subEl.innerHTML = el.outerHTML;
    el.replaceWith(subEl);
  }
  el.querySelectorAll('*').forEach((childEl) => removeStyle(childEl));
};
/* eslint-enable no-param-reassign */

const paste_preprocess = (_editor, args) => {
  // remove most style, replace important styles with semantic tags
  const {content} = args;
  const parser = new DOMParser();
  const doc = parser.parseFromString(content, 'text/html');
  doc.body.querySelectorAll('*').forEach((el) => removeStyle(el));
  args.content = doc.body.innerHTML;
};

const curatorTools = '| code strikethrough forecolor backcolor';

export default function Description({
  dcsDescription, path, mceKey, mceLabel, isCurator,
}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const editorRef = useRef(null);

  const submit = () => {
    if (editorRef.current) {
      const subJson = {
        authenticity_token,
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

  const checkSubmit = useCallback(debounce(submit, 900), []);

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
          toolbar: 'help | undo redo | blocks paste | bold italic superscript subscript removeformat '
                  + '| table link charmap | bullist numlist outdent indent | ltr rtl '
                  + `${(isCurator ? curatorTools : '')}`,
          table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | '
                  + 'tableinsertcolbefore tableinsertcolafter tabledeletecol',
          content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }',
          branding: false,
          paste_block_drop: true,
          paste_preprocess,
        }}
        onBlur={submit}
        onEditorChange={checkSubmit}
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
