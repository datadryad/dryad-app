import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderAutocomplete from './FunderAutocomplete';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';

function FunderForm({
  resourceId, origID, contributor, createPath, updatePath, removeFunction,
}) {
  const formRef = useRef();

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [acText, setAcText] = useState(contributor.contributor_name || '');
  const [acID, setAcID] = useState(contributor.name_identifier_id || '');

  const submitForm = (values) => {
    showSavingMsg();

    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {
      authenticity_token: csrf,
      contributor: {
        id: (`${values?.id}`.startsWith('new') ? null : values.id),
        contributor_name: acText,
        contributor_type: 'funder',
        identifier_type: (acID ? 'crossref_funder_id' : null),
        name_identifier_id: acID,
        resource_id: resourceId,
        award_number: values.award_number,
      },
    };

    // set up path
    let url;
    let method;
    if (submitVals.contributor.id) {
      url = updatePath;
      method = 'patch';
    } else {
      url = createPath;
      method = 'post';
    }

    // submit by json
    return axios({
      method,
      url,
      data: submitVals,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from funders save');
      }
      formRef.current.setFieldValue('id', data.data.id);
      showSavedMsg();
    });
  };

  return (
    <Formik
      initialValues={
            {
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
              controlOptions={
                                      {
                                        htmlId: `contrib_${contributor.id}`,
                                        labelText: 'Granting Organization',
                                        isRequired: false,
                                      }
                                    }
            />
          </div>
          {/* eslint-disable jsx-a11y/label-has-associated-control */}
          <div className="c-input">
            <label className="c-input__label" htmlFor={`contributor_award_number__${contributor.id}`}>Award
              Number
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
          {/* eslint-enable jsx-a11y/label-has-associated-control */}

          <a
            role="button"
            className="remove_record t-describe__remove-button o-button__remove"
            rel="nofollow"
            href="#"
            onClick={(e) => {
              e.preventDefault();
              showModalYNDialog('Are you sure you want to remove this funder?', () => {
                removeFunction(formRef.current?.values?.id, origID); // this sends the database id and the original id (key)
              });
            }}
          >remove
          </a>
        </Form>
      )}
    </Formik>
  );
}

export default FunderForm;

// resourceId, origID, contributor, createPath, updatePath, removeFunction

FunderForm.propTypes = {
  resourceId: PropTypes.string.isRequired,
  origID: PropTypes.string.isRequired,
  contributor: PropTypes.object.isRequired,
  createPath: PropTypes.string.isRequired,
  updatePath: PropTypes.string.isRequired,
  removeFunction: PropTypes.func.isRequired,
};
