import React from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';

const Title = ({ resource, path }) => {
  // see https://stackoverflow.com/questions/54808071/cant-verify-csrf-token-authenticity-rails-react for other options
  const csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content");

  return (
    <Formik
      initialValues={{ title: resource.title, id: resource.id, authenticity_token: csrf }}

      onSubmit={(values, { setSubmitting }) => {
        axios.patch(path, values, { headers: {'Content-Type': 'application/json; charset=utf-8', 'Accept': 'application/json'} })
          .then((data) =>
            {
              console.log(data);
            }
          )
      }}
    >
      <Form>
        <strong>
          <label className="required c-input__label" htmlFor="title">Dataset Title</label>
        </strong><br />
        <Field name="title" type="text" className="title c-input__text" size="130" maxLength="255" />
        <Field name="id" type="hidden" />
        <Field name="authenticity_token" type="hidden" />

        <button type="submit">Submit</button>
      </Form>
    </Formik>
  );
};

export default Title;