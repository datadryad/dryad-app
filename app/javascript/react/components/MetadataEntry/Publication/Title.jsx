import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import axios from 'axios';
import {showSavedMsg, showSavingMsg, upCase} from '../../../../lib/utils';

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

function Title({resource, setResource}) {
  const formRef = useRef();
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  return (
    <Formik
      initialValues={{title: (resource.title || ''), id: resource.id, authenticity_token}}
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        showSavingMsg();
        axios.patch(
          '/stash_datacite/titles/update',
          values,
          {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
        )
          .then((data) => {
            if (data.status !== 200) {
              console.log('Not a 200 response while saving Title form');
            }
            setResource((r) => ({...r, title: values.title}));
            showSavedMsg();
            setSubmitting(false);
          });
      }}
    >
      {(formik) => (
        <Form style={{margin: '2em auto 1em'}} className="input-stack">
          <label className="required o-heading__level4 upcase" htmlFor={`title__${resource.id}`}>
            {upCase(resource.resource_type.resource_type)} title
          </label>
          <Field
            name="title"
            type="text"
            className="title c-input__text"
            id={`title__${resource.id}`}
            onBlur={() => { // formRef.current.handleSubmit();
              formik.handleSubmit();
            }}
            required
            aria-errormessage="title_error"
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
  setResource: PropTypes.func.isRequired,
};

export default Title;