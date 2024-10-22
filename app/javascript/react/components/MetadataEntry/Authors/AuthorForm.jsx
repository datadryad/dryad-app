import React, {useState, useRef} from 'react';
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import RorAutocomplete from '../RorAutocomplete';

// author below has nested affiliation
export default function AuthorForm({
  author, update, remove, ownerId,
}) {
  const formRef = useRef(0);

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [acText, setAcText] = useState(author?.affiliations[0]?.long_name || '');
  const [acID, setAcID] = useState(author?.affiliations[0]?.ror_id || '');

  const submitForm = (values) => {
    showSavingMsg();

    // set up values
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

    const submitVals = {
      authenticity_token: csrf,
      author: {
        id: values.id,
        author_first_name: values.author_first_name,
        author_last_name: values.author_last_name,
        author_email: values.author_email,
        resource_id: author.resource_id,
        affiliation: {long_name: acText, ror_id: acID},
      },
    };

    // submit by json
    return axios.patch(
      '/stash_datacite/authors/update',
      submitVals,
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Accept: 'application/json',
        },
      },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from author save');
      }
      update((authors) => authors.map((a) => (a.id === values.id ? data.data : a)));
      showSavedMsg();
    });
  };

  return (
    <Formik
      initialValues={
        {
          author_first_name: (author.author_first_name || ''),
          author_last_name: (author.author_last_name || ''),
          author_email: (author.author_email || ''),
          id: (author.id),
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="author-form">
          <Field name="id" type="hidden" />
          <div className="input-stack">
            <label className="input-label" htmlFor={`author_first_name__${author.id}`}>
              First name
            </label>
            <Field
              id={`author_first_name__${author.id}`}
              name="author_first_name"
              type="text"
              className="c-input__text"
              aria-errormessage="author_fname_error"
              onBlur={() => { // defaults to formik.handleBlur
                formik.handleSubmit();
              }}
            />
          </div>
          <div className="input-stack">
            <label className="input-label" htmlFor={`author_last_name__${author.id}`}>
              Last name
            </label>
            <Field
              id={`author_last_name__${author.id}`}
              name="author_last_name"
              type="text"
              className="c-input__text"
              aria-errormessage="author_lname_error"
              onBlur={() => { // defaults to formik.handleBlur
                formik.handleSubmit();
              }}
            />
          </div>
          <div className="input-stack">
            <RorAutocomplete
              formRef={formRef}
              acText={acText}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
              controlOptions={{
                htmlId: `instit_affil_${author.id}`,
                labelText: 'Institutional affiliation',
                isRequired: true,
                errorId: 'author_aff_error',
              }}
            />
          </div>
          <div className="input-stack">
            <label className={`input-label ${(author.author_orcid ? 'required' : 'optional')}`} htmlFor={`author_email__${author.id}`}>
              Author email
            </label>
            <Field
              id={`author_email__${author.id}`}
              name="author_email"
              type="text"
              className="c-input__text"
              aria-errormessage="author_email_error"
              onBlur={() => { // defaults to formik.handleBlur
                formik.handleSubmit();
              }}
            />
          </div>
          { ownerId !== author.id && (
            <span>
              <button
                type="button"
                className="remove-record"
                onClick={() => {
                  showModalYNDialog('Are you sure you want to remove this author?', () => {
                    remove(author.id, author.resource_id);
                    // deleteItem(auth.id);
                  });
                }}
                aria-label="Remove author"
                title="Remove"
              >
                <i className="fas fa-trash-can" aria-hidden="true" />
              </button>
            </span>
          )}
        </Form>
      )}
    </Formik>
  );
}

AuthorForm.propTypes = {
  author: PropTypes.object.isRequired,
  update: PropTypes.func.isRequired,
  remove: PropTypes.func.isRequired,
  ownerId: PropTypes.number.isRequired,
};
