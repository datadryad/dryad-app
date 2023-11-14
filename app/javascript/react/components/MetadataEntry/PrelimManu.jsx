import React, {useState, useRef} from 'react';
import axios from 'axios';
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import PrelimAutocomplete from './PrelimAutocomplete';

function PrelimManu({
  resourceId,
  identifierId,
  acText,
  setAcText,
  acID,
  setAcID,
  msId,
  setMsId,
}) {
  const formRef = useRef();

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [importError, setImportError] = useState('');

  const submitForm = (values) => {
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
      msid: values.msId,
      do_import: values.isImport,
    };

    setMsId(values.msId);

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
        console.log('Response failure not a 200 response from manuscript information save/import');
      }
      setImportError(data.data.error || '');
      showSavedMsg();

      if (data.data.reloadPage) {
        setImportError('Just a moment . . . Reloading imported data');
        window.location.reload(true);
      }
    });
  };

  return (
    <Formik
      initialValues={
        {
          msId: msId || '',
          isImport: false,
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="c-input__inline">
          <div className="c-import__form-section" style={{width: '100%'}}>
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
                      htmlId: 'publication',
                      labelText: 'Journal name',
                      isRequired: true,
                    }
                  }
                />
              </div>
              <div className="c-input">
                <label className="c-input__label required" htmlFor="msId">
                  Manuscript number
                </label>
                <Field
                  className="c-input__text"
                  placeholder="APPS-D-17-00113"
                  type="text"
                  name="msId"
                  id="msId"
                  onBlur={() => { // defaults to formik.handleBlur
                    formRef.current.values.isImport = false;
                    formik.handleSubmit();
                  }}
                />
                <Field name="isImport" type="hidden" />
              </div>
            </div>
            <div>
              <button
                type="button"
                name="commit"
                className="o-button__import-manuscript"
                onClick={() => {
                  formRef.current.values.isImport = true;
                  formik.handleSubmit();
                }}
                disabled={(acText === '' || acID === '' || formRef?.current?.values.msId === '')}
              >
                Import manuscript metadata
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

PrelimManu.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  identifierId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  acText: PropTypes.string.isRequired,
  setAcText: PropTypes.func.isRequired,
  acID: PropTypes.string.isRequired,
  setAcID: PropTypes.func.isRequired,
  msId: PropTypes.string.isRequired,
  setMsId: PropTypes.func.isRequired,
};
