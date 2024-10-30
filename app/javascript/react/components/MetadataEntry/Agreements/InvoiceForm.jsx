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

export default function InvoiceForm({resource, setResource, ownerId}) {
  const owner = resource.authors.find((a) => a.id === ownerId);
  const [name, setName] = useState(null);
  const [email, setEmail] = useState(null);
  const formRef = useRef(null);

  useEffect(() => {
    async function getCustomer() {
      axios.get(`/stash_datacite/authors/${owner.id}/invoice`).then((data) => {
        if (data.data.name && data.data.email) {
          setName(data.data.name);
          setEmail(data.data.email);
        }
      });
    }
    if (owner.stripe_customer_id) {
      getCustomer();
    } else {
      setName([owner?.author_first_name, owner?.author_last_name].filter(Boolean).join(' '));
      setEmail(owner?.author_email);
    }
  }, []);

  if (email === null) return <p><i className="fa fa-spinner fa-spin" role="img" aria-label="Loading" /></p>;
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
            author: {id: owner.id, resource_id: resource.id},
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
            <span className="input-line" style={{alignItems: 'baseline', gap: '.5ch'}}>
              <label className="input-label" htmlFor="invoice-name">Name</label>
              <Field
                id="invoice-name"
                name="name"
                type="text"
                className="c-input__text"
              />
            </span>
            <span className="input-line" style={{alignItems: 'baseline', gap: '.5ch'}}>
              <label className="input-label" htmlFor="invoice-email">Email</label>
              <span className="input-stack">
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
