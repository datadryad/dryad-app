import React, {useState, useEffect, useRef} from 'react';
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export default function AuthorForm({dryadAuthor, affiliation}) {

  const formRef = useRef();
  return (
      <Formik
          initialValues={
            {
              author_first_name: (dryadAuthor.author_first_name || ''),
              author_last_name: (dryadAuthor.author_last_name || ''),
              author_email: (dryadAuthor.author_email || ''),
              id: (dryadAuthor.id),
            }
          }
          innerRef={formRef}
          onSubmit={(values) => { // {setSubmitting}
            // submitForm(values).then(() => { setSubmitting(false); });
            console.log(values);
          }}
      >
        {(formik) => (
            <Form className="c-input__inline">
              <Field name="id" type="hidden" />
              <div className="c-input">
                <label className="c-input__label required" htmlFor={`author_first_name__${dryadAuthor.id}`}>
                  First Name
                </label>
                <Field
                    id={`author_first_name__${dryadAuthor.id}`}
                    name="author_first_name"
                    type="text"
                    className="c-input__text"
                    onBlur={() => { // defaults to formik.handleBlur
                      formik.handleSubmit();
                    }}
                />
              </div>
              <div className="c-input">
                <label className="c-input__label required" htmlFor={`author_last_name__${dryadAuthor.id}`}>
                  Last Name
                </label>
                <Field
                    id={`author_last_name__${dryadAuthor.id}`}
                    name="author_last_name"
                    type="text"
                    className="c-input__text"
                    onBlur={() => { // defaults to formik.handleBlur
                      formik.handleSubmit();
                    }}
                />
              </div>
            </Form>
        )}
      </Formik>
  );
}