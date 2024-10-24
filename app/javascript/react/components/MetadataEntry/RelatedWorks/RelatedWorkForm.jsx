import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import RelatedWorksErrors, {urlCheck, verifiedCheck} from './RelatedWorksErrors';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function RelatedWorkForm(
  {
    relatedIdentifier, workTypes, removeFunction, updateWork,
  },
) {
  const formRef = useRef();

  const submitForm = (values) => {
    showSavingMsg();

    // set up values
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

    const sdri = {
      id: values.id,
      resource_id: relatedIdentifier.resource_id,
      work_type: values.work_type,
      related_identifier: values.related_identifier,
    };

    if (urlCheck(values.related_identifier)) {
      fetch(values.related_identifier, {method: 'HEAD', mode: 'cors'})
        .then((res) => {
          if (res.ok) sdri.verified = true;
        }).catch();
    }

    // submit by json
    return axios.patch(
      '/stash_datacite/related_identifiers/update',
      {authenticity_token, stash_datacite_related_identifier: sdri},
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
        {(formik) => (
          <Form
            className={`work-form${(!urlCheck(relatedIdentifier.related_identifier) && ' err')
              || (!verifiedCheck(relatedIdentifier) && ' warn') || ''}`}
          >
            <Field name="id" type="hidden" />
            <div className="input-stack">
              <label className="input-label" htmlFor={`work_type__${relatedIdentifier.id}`}>
                Work type
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
            <div className="input-stack">
              <label className="input-label" htmlFor={`related_identifier__${relatedIdentifier.id}`}>
                DOI or other URL
              </label>
              <Field
                id={`related_identifier__${relatedIdentifier.id}`}
                name="related_identifier"
                type="text"
                aria-errormessage="works_error"
                aria-describedby={`${relatedIdentifier.id}url-ex`}
                className="c-input__text"
                onBlur={() => { // defaults to formik.handleBlur
                  formik.handleSubmit();
                }}
              />
              <div id={`${relatedIdentifier.id}url-ex`}><i />https://doi.org/10.1594/PANGAEA.726855</div>
            </div>
            <span style={{display: 'block', alignSelf: 'start'}}>
              <button
                type="button"
                className="remove-record"
                onClick={() => {
                  showModalYNDialog('Are you sure you want to remove this work?', () => {
                    removeFunction(relatedIdentifier.id);
                  });
                }}
                aria-label="Remove work"
                title="Remove"
              >
                <i className="fas fa-trash-can" aria-hidden="true" />
              </button>
            </span>
          </Form>
        )}
      </Formik>
      <div role="status">
        <RelatedWorksErrors relatedIdentifier={relatedIdentifier} />
      </div>
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
