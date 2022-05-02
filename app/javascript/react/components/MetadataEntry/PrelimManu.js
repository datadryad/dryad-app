import React, {useState, useRef} from 'react';
import axios from 'axios';
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import PrelimAutocomplete from "./PrelimAutocomplete";

function PrelimManu({
    resourceId,
    identifierId,
    publication_name,
    publication_issn,
    msid,
                    }) {
  const formRef = useRef();

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [acText, setAcText] = useState( publication_name?.value || '');
  const [acID, setAcID] = useState( publication_issn?.value || '');
  const [importError, setImportError] = useState('');

  const submitForm = (values) => {
    console.log(`${(new Date()).toISOString()}: Saving Preliminaries -- manuscript in progress`);
    showSavingMsg();

    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

    const submitVals = {
      authenticity_token: csrf,
      import_type: 'manuscript',
      publication_name: acText,
      identifier_id: identifierId,
      resource_id: resourceId,
      publication_issn: acID,
      msid: values.msid,
      do_import: values.isImport,
    };

    // submit by json
    return axios.patch(
        '/stash_datacite/publications/update',
        submitVals,
        {
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            Accept: 'application/json',
          },
        },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from manuscript information save');
      }

      setImportError(data.data['error'] || '');

      showSavedMsg();

      if(data.data['reloadPage']){
        setImportError('Just a moment . . . Reloading imported data');
        location.reload(true);
      }
    });
  };

  return (
      <Formik
          initialValues={
            {
              msid: msid.value || '',
              isImport: false
            }
          }
          innerRef={formRef}
          onSubmit={(values, {setSubmitting}) => {
            submitForm(values).then(() => { setSubmitting(false); });
          }}
      >
        {(formik) => (
            <Form className="c-input__inline">
              <div className="c-import__form-section">
                <p>Please provide the following information. You may either enter the information and leave it or choose
                  to autofill your dataset based on the information you supply below.</p>

                <div className="c-input__inline">
                  <div className="c-input">
                    <PrelimAutocomplete
                        formRef={formRef}
                        acText={acText}
                        setAcText={setAcText}
                        acID={acID}
                        setAcID={setAcID}
                        controlOptions={
                          {
                            htmlId: `publication`,
                            labelText: 'Journal Name',
                            isRequired: true,
                          }
                        }
                    />
                  </div>
                  <div className="c-input">
                    <label className="c-input__label required" htmlFor="msid">
                      Manuscript Number
                    </label>
                    <Field
                        className="c-input__text"
                        placeholder="APPS-D-17-00113"
                        type="text"
                        name="msid"
                        id="msid"
                        onBlur={() => { // defaults to formik.handleBlur
                          formRef.current.values['isImport'] = false;
                          formik.handleSubmit();
                        }}
                    />
                    <Field name="isImport" type="hidden" />
                  </div>
                </div>
                <div>
                  <button type="button" name="commit" className="o-button__import-manuscript"
                          onClick={() => {
                            formRef.current.values['isImport'] = true;
                            formik.handleSubmit();
                          }}
                          disabled={(acText === '' || acID === '' || formRef?.current?.values['msid'] === '' )}>
                    Import Manuscript Metadata
                  </button>
                </div>
                <div id="population-warnings" className="o-metadata__autopopulate-message">
                  {importError}
                </div>
              </div>
            </Form>
        )}
      </Formik>
  );
}

export default PrelimManu;