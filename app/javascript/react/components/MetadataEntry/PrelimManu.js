import React, {useState, useRef} from 'react';
import axios from 'axios';
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import PrelimAutocomplete from "./PrelimAutocomplete";

function PrelimManu() {
  const formRef = useRef();

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [acText, setAcText] = useState( '');
  const [acID, setAcID] = useState('');

  const submitForm = (values) => {
    console.log(`${(new Date()).toISOString()}: Saving Preliminaries -- manuscript in progress`);
    // showSavingMsg();

    /*
    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    // these need fixing
    const submitVals = {
      authenticity_token: csrf,
      contributor: {
        id: values.id,
        contributor_name: acText,
        contributor_type: 'funder',
        identifier_type: 'crossref_funder_id', // needs to be set for datacite mapping, even if no id gotten from crossref
        name_identifier_id: acID,
        award_number: values.award_number,
        resource_id: resourceId,
      },
    };

    // submit by json
    return axios.patch(
        updatePath,
        submitVals,
        {
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            Accept: 'application/json',
          },
        },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from funders save');
      }

      // forces data update in the collection containing me
      updateFunder(data.data);
      showSavedMsg();
    });
     */
  };

  return (
      <Formik
          initialValues={
            {
              publication: 'test',
              msid: '12837',
            }
          }
          innerRef={formRef}
          onSubmit={(values, {setSubmitting}) => {
            // submitForm(values).then(() => { setSubmitting(false); });
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

                    <input type="hidden" name="publication_issn" id="publication_issn"/>
                    <input type="hidden" name="publication_name" id="publication_name"/>
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
                        id="msid"/>
                  </div>
                </div>
                <div>
                  <button type="submit" name="commit" className="o-button__import-manuscript">
                    Import Manuscript Metadata
                  </button>
                </div>
                <div id="population-warnings" className="o-metadata__autopopulate-message">
                  Some warnings here.
                </div>
              </div>
            </Form>
        )}
      </Formik>
  );
}

export default PrelimManu;