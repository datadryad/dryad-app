import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';

function FunderForm({resourceId, contributor, createPath, updatePath}) {
  const formRef = useRef();

  return (
      <Formik
          initialValues={{title: (resource.title || ''), id: resource.id, authenticity_token: (csrf || '')}}
          innerRef={formRef}
          onSubmit={(values, {setSubmitting}) => {
            /*
            showSavingMsg();
            axios.patch(path, values, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
                .then((data) => {
                  if (data.status !== 200) {
                    console.log('Not a 200 response while saving Title form');
                  }
                  showSavedMsg();
                  setSubmitting(false);
                });
             */
          }}
      >
        {(formik) => (
            <Form className="c-input__inline">
              <Field name="id" type="hidden" />
              <Field name="authenticity_token" type="hidden" />
            </Form>
        )}
      </Formik>
  );
}