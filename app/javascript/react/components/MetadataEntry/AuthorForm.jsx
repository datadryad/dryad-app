import React, {useState, useRef} from 'react';
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showModalYNDialog, showSavedMsg, showSavingMsg} from '../../../lib/utils';
import RorAutocomplete from './RorAutocomplete';

// dryadAuthor below has nested affiliation
export default function AuthorForm({dryadAuthor, removeFunction, correspondingAuthorId}) {
  const formRef = useRef(0);

  // the follow autocomplete items are lifted up state that is normally just part of the form, but doesn't work with Formik
  const [acText, setAcText] = useState(dryadAuthor?.affiliation?.long_name || '');
  const [acID, setAcID] = useState(dryadAuthor?.affiliation?.ror_id || '');

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
        resource_id: dryadAuthor.resource_id,
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

      // The funders have a method to update the parent collection (updateFunder(data.data)) but doesn't seem necessary
      // for this item and state is already in sync
      // console.log('saved data returned from server', data.data); // can also check acID and acText
      showSavedMsg();
    });
  };

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
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="c-input__inline">
          <Field name="id" type="hidden" />
          <div className="c-input">
            <label className="c-input__label required" htmlFor={`author_first_name__${dryadAuthor.id}`}>
              First name
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
              Last name
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
          <div className="c-input">
            <RorAutocomplete
              formRef={formRef}
              acText={acText}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
              // name={dryadAuthor.affiliation.long_name}
              // id={dryadAuthor.affiliation.ror_id}
              controlOptions={{htmlId: `instit_affil_${dryadAuthor.id}`, labelText: 'Institutional affiliation', isRequired: true}}
            />
          </div>
          <div className="c-input">
            <label className={`c-input__label ${(dryadAuthor.author_orcid ? 'required' : '')}`} htmlFor={`author_email__${dryadAuthor.id}`}>
              Author email
            </label>
            <Field
              id={`author_email__${dryadAuthor.id}`}
              name="author_email"
              type="text"
              className="c-input__text"
              onBlur={() => { // defaults to formik.handleBlur
                formik.handleSubmit();
              }}
            />
          </div>
          { correspondingAuthorId !== dryadAuthor.id
            && (
              <button
                type="button"
                className="t-describe__remove-button o-button__remove remove_record"
                onClick={() => {
                  showModalYNDialog('Are you sure you want to remove this author?', () => {
                    removeFunction(dryadAuthor.id, dryadAuthor.resource_id);
                    // deleteItem(auth.id);
                  });
                }}
              >
                remove
              </button>
            )}
        </Form>
      )}
    </Formik>
  );
}

AuthorForm.propTypes = {
  dryadAuthor: PropTypes.object.isRequired,
  removeFunction: PropTypes.func.isRequired,
  correspondingAuthorId: PropTypes.number.isRequired,
};
