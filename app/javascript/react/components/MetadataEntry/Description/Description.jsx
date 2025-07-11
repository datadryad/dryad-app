import React, {useState, useEffect, useCallback} from 'react';
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
  setResource, dcsDescription, mceLabel, curator,
}) {
  const [desc, setDesc] = useState('');
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const submit = (value) => {
    const subJson = {
      authenticity_token,
      description: {
        description: value,
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
        if (data.data) {
          setResource((r) => ({
            ...r,
            descriptions: [{...dcsDescription, description: data.data.description}, ...r.descriptions.filter((d) => d.id !== dcsDescription.id)],
          }));
        }
        showSavedMsg();
      });
  };

  const checkSubmit = useCallback(debounce(submit, 900), []);

  useEffect(() => {
    // copy and do not rerender on change
    setDesc(`${dcsDescription.description || ''}`);
  }, [dcsDescription]);

  return (
    <>
      <div className="input-line spaced">
        <span
          className={`input-label xl${(mceLabel.required ? ' required' : ' optional')}`}
          id={`${dcsDescription?.description_type}_label`}
        >
          {mceLabel.label}
        </span>
        {mceLabel.describe && <div id={`${dcsDescription?.description_type}-ex`}>{mceLabel.describe}</div>}
      </div>
      <Editor
        id={`editor_${dcsDescription?.description_type}`}
        onInit={(evt, editor) => {
          editor.getContainer().querySelector('.tox-statusbar__resize-handle').setAttribute('role', 'button');
          Array.from(editor.getContainer().querySelectorAll('div.tox-collection__item[aria-label]:not([role])')).forEach((b) => {
            b.setAttribute('role', 'button');
          });
          Array.from(editor.getContainer().querySelectorAll('.tox-menu[role="menu"] .tox-collection__group:not([role])')).forEach((g) => {
            g.setAttribute('role', 'group');
          });
          editor.getBody().setAttribute('aria-label', `${mceLabel.label} editor`);
          editor.getContainer().setAttribute('aria-labelledby', `${dcsDescription?.description_type}_label`);
          editor.getContainer().setAttribute('aria-errormessage', `${dcsDescription?.description_type}_error`);
          if (mceLabel.describe) editor.getContainer().setAttribute('aria-describedby', `${dcsDescription?.description_type}-ex`);
        }}
        tinymceScriptSrc="/tinymce/tinymce.min.js"
        licenseKey="gpl"
        initialValue={desc}
        init={{
          height: 300,
          width: '100%',
          menubar: false,
          plugins: 'advlist anchor autolink charmap code directionality help lists link table',
          toolbar: 'help | undo redo | blocks | bold italic superscript subscript removeformat '
                  + '| table link charmap | bullist numlist outdent indent | ltr rtl '
                  + `${(curator ? curatorTools : '')}`,
          table_toolbar: 'tableprops tabledelete | tableinsertrowbefore tableinsertrowafter tabledeleterow | '
                  + 'tableinsertcolbefore tableinsertcolafter tabledeletecol',
          content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:14px }',
          invalid_styles: {
            table: 'width height',
            tr: 'width height',
            th: 'width height',
            td: 'width height',
          },
          help_tabs: ['shortcuts', 'keyboardnav'],
          branding: false,
          paste_block_drop: true,
          paste_preprocess,
        }}
        onEditorChange={checkSubmit}
        onBlur={(_e, editor) => submit(editor.getContent())}
      />
    </>
  );
}

Description.propTypes = {
  setResource: PropTypes.func.isRequired,
  dcsDescription: PropTypes.object.isRequired,
  mceLabel: PropTypes.object.isRequired,
  curator: PropTypes.bool.isRequired,
};
