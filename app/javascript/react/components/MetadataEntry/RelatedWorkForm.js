import React, {useRef, useState} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';

function RelatedWorkForm(
    {relatedIdentifier,
    workTypes}
) {
  const formRef = useRef();

  return (
      <Formik
          initialValues={
            {
              work_type: (relatedIdentifier.work_type || ''),
              related_id: (relatedIdentifier.related_identifier || ''),
            }
          }
          innerRef={formRef}
          onSubmit={(values, {setSubmitting}) => {
            // submitForm(values).then(() => { setSubmitting(false);
            }}
      >
        {(formik) => (
            <Form className="c-input__inline">
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
                      <option value={opt[1]}>
                        {opt[0]}
                      </option>
                      ))}
                </Field>
              </div>
            </Form>
        )}
      </Formik>
  );
}

export default RelatedWorkForm;
