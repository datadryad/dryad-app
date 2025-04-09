import React, {useRef, useState, useEffect} from 'react';
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

const validateEmail = (value) => {
  if (value && !/^[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+$/i.test(value)) {
    return 'Invalid email address';
  }
  return null;
};

export default function InvoiceForm({resource, setResource}) {
  const {authors, users} = resource;
  const submitter = authors.find((a) => a.author_orcid === users.find((u) => u.role === 'submitter')?.orcid);
  const [name, setName] = useState(null);
  const [email, setEmail] = useState(null);
  const formRef = useRef(null);

  useEffect(() => {
    async function getCustomer() {
      axios.get(`/stash_datacite/authors/${submitter.id}/invoice`).then((data) => {
        if (data.data.name && data.data.email) {
          setName(data.data.name);
          setEmail(data.data.email);
        }
      });
    }
    if (submitter.stripe_customer_id) {
      getCustomer();
    } else {
      setName([submitter?.author_first_name, submitter?.author_last_name].filter(Boolean).join(' '));
      setEmail(submitter?.author_email);
    }
  }, []);

  if (email === null) return null;
  return (
    <Formik
      initialValues={
        {
          name: name || '',
          email: email || '',
        }
      }
      enableReinitialize
      innerRef={formRef}
      onSubmit={(values, {setTouched}) => {
        showSavingMsg();
        axios.patch(
          '/stash_datacite/authors/invoice',
          {
            authenticity_token: document.querySelector("meta[name='csrf-token']")?.getAttribute('content'),
            author: {id: submitter.id, resource_id: resource.id},
            customer_name: values.name,
            customer_email: values.email,
          },
          {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
        ).then((data) => {
          if (data.status !== 200) {
            console.log('Response failure not a 200 response from author invoice save');
          }
          setResource((r) => ({...r, authors: r.authors.map((a) => (a.id === data.data.id ? data.data : a))}));
          setName(values.name);
          setEmail(values.email);
          showSavedMsg();
          setTouched({});
        });
      }}
    >
      {({errors, touched, values}) => (
        <Form>
          <p>The invoice will be sent to:</p>
          <p className="input-line" style={{alignItems: 'baseline'}}>
            <span className="input-line" style={{flex: 1, alignItems: 'baseline', gap: '.5ch'}}>
              <label className="input-label" htmlFor="invoice-name">Name</label>
              <Field
                id="invoice-name"
                name="name"
                type="text"
                className="c-input__text"
                style={{flex: 1}}
              />
            </span>
            <span className="input-line" style={{flex: 1, alignItems: 'baseline', gap: '.5ch'}}>
              <label className="input-label" htmlFor="invoice-email">Email</label>
              <span className="input-stack" style={{flex: 1}}>
                <Field
                  id="invoice-email"
                  name="email"
                  type="text"
                  className="c-input__text"
                  aria-errormessage="email_error"
                  aria-invalid={errors.email && touched.email ? true : null}
                  validate={validateEmail}
                />
                {errors.email && touched.email && <span className="c-ac__error_message" id="email_error">{errors.email}</span>}
              </span>
            </span>
            <button
              type="submit"
              className="o-button__plain-text1"
              disabled={
                !(touched.name || touched.email)
                || !values.name || !values.email
                || (values.email === email && values.name === name)
                || errors.email
              }
            >Save
            </button>
          </p>
        </Form>
      )}
    </Formik>
  );
}
