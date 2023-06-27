import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderAutocomplete from './FunderAutocomplete';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';

function FunderForm({
  resourceId, contributor, updatePath, removeFunction, updateFunder, groupings,
}) {
  const formRef = useRef();

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [acText, setAcText] = useState(contributor.contributor_name || '');
  const [acID, setAcID] = useState(contributor.name_identifier_id || '');

  const submitForm = (values) => {
    console.log(`${(new Date()).toISOString()}: Saving funder`);
    showSavingMsg();

    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {
      authenticity_token: csrf,
      contributor: {
        id: values.id,
        contributor_name: acText,
        contributor_type: 'funder',
        identifier_type: 'crossref_funder_id', // needs to be set for datacite mapping, even if no id gotten from crossref
        name_identifier_id: acID,
        award_number: values.award_number,
        award_description: values.award_description,
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
  };

  return (
    <Formik
      initialValues={
        {
          award_description: (contributor.award_description || ''),
          award_number: (contributor.award_number || ''),
          id: (contributor.id || ''),
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="c-input__inline">
          <Field name="id" type="hidden" />
          <div className="c-input">
            <FunderAutocomplete
              formRef={formRef}
              acText={acText}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
              groupings={groupings}
              controlOptions={
                {
                  htmlId: `contrib_${contributor.id}`,
                  labelText: 'Granting organization',
                  isRequired: true,
                }
              }
            />
          </div>
          <div className="c-input">
            <label className="c-input__label" htmlFor={`contributor_award_number__${contributor.id}`}>Award
              number
            </label>
            <Field
              id={`contributor_award_number__${contributor.id}`}
              name="award_number"
              type="text"
              className="js-award_number c-input__text"
              onBlur={() => { // defaults to formik.handleBlur
                formik.handleSubmit();
              }}
            />
          </div>
          <div className="c-input">
            <label className="c-input__label" htmlFor={`contributor_award_description__${contributor.id}`}>Program/division
            </label>
            <Field
              id={`contributor_award_description__${contributor.id}`}
              name="award_description"
              type="text"
              className="js-award_description c-input__text"
              onBlur={() => { // defaults to formik.handleBlur
                formik.handleSubmit();
              }}
            />
          </div>
          <button
            type="button"
            className="t-describe__remove-button o-button__remove"
            onClick={() => {
              showModalYNDialog('Are you sure you want to remove this funder?', () => {
                removeFunction(contributor.id);
              });
            }}
          >remove
          </button>
        </Form>
      )}
    </Formik>
  );
}

export default FunderForm;

// resourceId, contributor, createPath, updatePath, removeFunction, updateFunder

FunderForm.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  contributor: PropTypes.object.isRequired,
  updatePath: PropTypes.string.isRequired,
  removeFunction: PropTypes.func.isRequired,
  updateFunder: PropTypes.func.isRequired,
};
