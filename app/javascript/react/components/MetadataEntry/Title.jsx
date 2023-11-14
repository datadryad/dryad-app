import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

/* Formik makes it difficult to get a hold of some of the context to do some things manually unless you make the forms very
   verbose like the initial, "building Formik" ones at https://formik.org/docs/tutorial .  If you use the compact and less
   verbose function syntax (their final built examples) then it's difficult to get the context for manually triggering something like a submit.

  This page gives some options, https://stackoverflow.com/questions/49525057/react-formik-use-submitform-outside-formik ,
  but it doesn't seem to have complete information about  useFormikContext(). I got undefined variables or could only bind
  to the verbose version.  I believe it is also more geared toward for exposing context outside the component than within.

  I finally got a useRef solution to work. Look at formRef and useRef below.  Also 'formRef.current.submit()'. This is
  based on https://stackoverflow.com/questions/60491891/how-do-i-access-current-value-of-a-formik-field-without-submitting
  and the answer by Muhammed Rafeeq .  The solution by aturan23 seems to destructure the variables and doesn't cause errors,
  but the variables were then not accessible within my onBlur handler.
 */

function Title({resource, path, type}) {
  // see https://stackoverflow.com/questions/54808071/cant-verify-csrf-token-authenticity-rails-react for other options
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const formRef = useRef();

  return (
    <Formik
      initialValues={{title: (resource.title || ''), id: resource.id, authenticity_token: (csrf || '')}}
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        showSavingMsg();
        axios.patch(path, values, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
          .then((data) => {
            if (data.status !== 200) {
              console.log('Not a 200 response while saving Title form');
            }
            showSavedMsg();
            setSubmitting(false);
          });
      }}
    >
      {(formik) => (
        <Form className="c-input">
          <label className="required c-input__label" htmlFor={`title__${resource.id}`}>{type} title</label>
          <Field
            name="title"
            type="text"
            className="title c-input__text"
            size="130"
            id={`title__${resource.id}`}
            onBlur={() => { // formRef.current.handleSubmit();
              formik.handleSubmit();
            }}
          />
          <Field name="id" type="hidden" />
          <Field name="authenticity_token" type="hidden" />
        </Form>
      )}
    </Formik>
  );
}

// This has some info https://blog.logrocket.com/validating-react-component-props-with-prop-types-ef14b29963fc/
Title.propTypes = {
  resource: PropTypes.object.isRequired,
  path: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
};

export default Title;
