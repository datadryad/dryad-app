import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import RelatedWorksErrors from './RelatedWorksErrors';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';

function RelatedWorkForm(
  {
    relatedIdentifier, workTypes, removeFunction, updateWork,
  },
) {
  const formRef = useRef();

  const submitForm = (values) => {
    console.log(`${(new Date()).toISOString()}: Saving related work`);
    showSavingMsg();

    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

    const submitVals = {
      authenticity_token: csrf,
      stash_datacite_related_identifier: {
        id: values.id,
        resource_id: relatedIdentifier.resource_id,
        work_type: values.work_type,
        related_identifier: values.related_identifier,
      },
    };

    // submit by json
    return axios.patch(
      '/stash_datacite/related_identifiers/update',
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
      updateWork(data.data);
      showSavedMsg();
    });
  };

  return (
    <>
      <Formik
        initialValues={
            {
              id: relatedIdentifier.id,
              work_type: (relatedIdentifier.work_type || ''),
              related_identifier: (relatedIdentifier.related_identifier || ''),
            }
          }
        innerRef={formRef}
        onSubmit={(values, {setSubmitting}) => {
          submitForm(values).then(() => { setSubmitting(false); });
        }}
      >
        {/* eslint-disable jsx-a11y/label-has-associated-control */}
        {(formik) => (
          <Form className="c-input__inline">
            <Field name="id" type="hidden" />
            <div className="c-input">
              <label className="c-input__label" htmlFor={`work_type__${relatedIdentifier.id}`}>
                Work Type
              </label>
              <Field
                id={`work_type__${relatedIdentifier.id}`}
                name="work_type"
                as="select"
                className="c-input__select"
                onBlur={() => { // defaults to formik.handleBlur
                  formik.handleSubmit();
                }}
              >
                {workTypes.map((opt) => (
                  <option key={opt[1]} value={opt[1]}>
                    {opt[0]}
                  </option>
                ))}
              </Field>
            </div>
            <div className="c-input">
              <label className="c-input__label" htmlFor={`related_identifier__${relatedIdentifier.id}`}>
                Identifier or external url
              </label>
              <Field
                id={`related_identifier__${relatedIdentifier.id}`}
                name="related_identifier"
                type="text"
                size="40"
                placeholder="example: https://doi.org/10.1594/PANGAEA.726855"
                className="c-input__text"
                onBlur={() => { // defaults to formik.handleBlur
                  formik.handleSubmit();
                }}
              />
            </div>

            {/* eslint-disable jsx-a11y/anchor-is-valid */}
            <a
              role="button"
              className="t-describe__remove-button o-button__remove"
              rel="nofollow"
              href="#"
              onClick={(e) => {
                e.preventDefault();
                showModalYNDialog('Are you sure you want to remove this related work?', () => {
                  removeFunction(relatedIdentifier.id);
                });
              }}
            >remove
            </a>
            {/* eslint-enable jsx-a11y/anchor-is-valid */}
          </Form>
        )}
      </Formik>
      {/* eslint-enable jsx-a11y/label-has-associated-control */}
      <RelatedWorksErrors relatedIdentifier={relatedIdentifier} />
    </>
  );
}

export default RelatedWorkForm;

// relatedIdentifier, workTypes, removeFunction, updateWork,
RelatedWorkForm.propTypes = {
  relatedIdentifier: PropTypes.object.isRequired,
  workTypes: PropTypes.array.isRequired,
  removeFunction: PropTypes.func.isRequired,
  updateWork: PropTypes.func.isRequired,
};
