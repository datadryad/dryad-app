import React, {useRef, useCallback} from 'react';
import {Editor} from '@tinymce/tinymce-react';
import axios from 'axios';
import {debounce} from 'lodash';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

/* eslint-disable no-param-reassign */
const removeStyle = (el) => {
  const b = ['bold', '700'].includes(el.style.fontWeight);
  const i = el.style.fontStyle === 'italic';
  const sup = el.style.verticalAlign === 'super';
  const sub = el.style.verticalAlign === 'sub';
  [...el.attributes].forEach((attr) => attr.name !== 'href' && el.removeAttribute(attr.name));
  if (el.tagName === 'A' && el.attributes.length === 0) {
    const span = document.createElement('span');
    span.innerHTML = el.innerHTML;
    el.replaceWith(span);
    el = span;
  }
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
  setResource, dcsDescription, mceLabel, admin,
}) {
  const editorRef = useRef(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

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
      axios.patch(
        '/stash_datacite/descriptions/update',
        subJson,
        {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
      )
        .then((data) => {
          const {description_type} = data.data;
          setResource((r) => ({...r, descriptions: [data.data, ...r.descriptions.filter((d) => d.description_type !== description_type)]}));
          showSavedMsg();
        });
    }
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  return (
    <>
      <div className="input-line spaced">
        <label
          className={`input-label xl${(mceLabel.required ? ' required' : ' optional')}`}
          id={`${dcsDescription.description_type}_label`}
          htmlFor={`editor_${dcsDescription.description_type}`}
        >
          {mceLabel.label}
        </label>
        {mceLabel.describe && <div id={`${mceLabel.label}-ex`}>{mceLabel.describe}</div>}
      </div>
      <Editor
        id={`editor_${dcsDescription.description_type}`}
        onInit={(evt, editor) => { editorRef.current = editor; }}
        tinymceScriptSrc="/tinymce/tinymce.min.js"
        licenseKey="gpl"
        initialValue={dcsDescription?.description}
        init={{
          height: 300,
          width: '100%',
          menubar: false,
          plugins: 'advlist anchor autolink charmap code directionality help lists link table',
          toolbar: 'help | undo redo | blocks paste | bold italic superscript subscript removeformat '
                  + '| table link charmap | bullist numlist outdent indent | ltr rtl '
                  + `${(admin ? curatorTools : '')}`,
          table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | '
                  + 'tableinsertcolbefore tableinsertcolafter tabledeletecol',
          content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }',
          invalid_styles: {
            table: 'width height',
            tr: 'width height',
            th: 'width height',
            td: 'width height',
          },
          branding: false,
          paste_block_drop: true,
          paste_preprocess,
        }}
        onBlur={submit}
      />
    </>
  );
}

Description.propTypes = {
  setResource: PropTypes.func.isRequired,
  dcsDescription: PropTypes.object.isRequired,
  mceLabel: PropTypes.object.isRequired,
  admin: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool,
  ]).isRequired,
};
