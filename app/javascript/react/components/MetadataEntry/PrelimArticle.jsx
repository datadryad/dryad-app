import React, {useState, useRef} from 'react';
import axios from 'axios';
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import PrelimAutocomplete from './PrelimAutocomplete';

function PrelimArticle({
  resourceId,
  identifierId,
  acText,
  setAcText,
  acID,
  setAcID,
  relatedIdentifier,
  setRelatedIdentifier,
}) {
  const formRef = useRef();

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [importError, setImportError] = useState('');

  const submitForm = (values) => {
    console.log(`${(new Date()).toISOString()}: Saving Preliminary DOI Article info`);
    showSavingMsg();

    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

    const submitVals = {
      authenticity_token: csrf,
      import_type: 'published',
      publication_name: acText,
      identifier_id: identifierId,
      resource_id: resourceId,
      publication_issn: acID,
      primary_article_doi: values.primary_article_doi,
      do_import: values.isImport,
    };

    setRelatedIdentifier(values.primary_article_doi);

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
        console.log('Response failure not a 200 response from doi article information save/import');
      }

      setImportError(data.data.error || '');

      showSavedMsg();

      if (data.data.reloadPage) {
        setImportError('Just a moment . . . Reloading imported data');
        /* eslint-disable no-restricted-globals */
        location.reload(true);
        /* eslint-enable no-restricted-globals */
      }
    });
  };

  return (
    <Formik
      initialValues={
        {
          primary_article_doi: relatedIdentifier,
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
          <div className="c-import__form-section">
            <p>Please provide the following information. You may either enter the information and leave it or choose
              to autofill your dataset based on the information you supply below.
            </p>

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
                      labelText: 'Journal Name',
                      isRequired: false,
                    }
                  }
                />
              </div>
              <div className="c-input">
                {/* eslint-disable jsx-a11y/label-has-associated-control */}
                <label className="c-input__label required" htmlFor="primary_article_doi">
                  DOI
                </label>
                <Field
                  className="c-input__text"
                  placeholder="5702.125/qlm.1266rr"
                  type="text"
                  name="primary_article_doi"
                  id="primary_article_doi"
                  onBlur={() => { // defaults to formik.handleBlur
                    formRef.current.values.isImport = false;
                    formik.handleSubmit();
                  }}
                />
                {/* eslint-enable jsx-a11y/label-has-associated-control */}
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
                disabled={(acText === '' || formRef?.current?.values.primary_article_doi === '')}
              >
                Import Article Metadata
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

export default PrelimArticle;

PrelimArticle.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  identifierId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  acText: PropTypes.string.isRequired,
  setAcText: PropTypes.func.isRequired,
  acID: PropTypes.string.isRequired,
  setAcID: PropTypes.func.isRequired,
  relatedIdentifier: PropTypes.string.isRequired,
  setRelatedIdentifier: PropTypes.func.isRequired,
};
