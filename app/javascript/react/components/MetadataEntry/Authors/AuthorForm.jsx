import React, {useState, useRef} from 'react';
import {Field, Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import Affiliations from './Affiliations';
import OrcidInfo from './OrcidInfo';

export default function AuthorForm({
  author, update, ownerId, admin,
}) {
  const formRef = useRef(0);
  const [affiliations, setAffiliations] = useState(author?.affiliations);

  const submitForm = (values) => {
    const submit = {
      id: values.id,
      author_first_name: values.author_first_name,
      author_last_name: values.author_last_name,
      author_org_name: values.author_org_name || null,
      author_email: values.author_email,
      resource_id: author.resource_id,
      affiliations,
    };
    return update(submit);
  };

  const validateEmail = (value) => {
    if (value && !/^[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+$/i.test(value)) {
      return 'Invalid email address';
    }
    return null;
  };

  return (
    <Formik
      initialValues={
        {
          author_first_name: (author.author_first_name || ''),
          author_last_name: (author.author_last_name || ''),
          author_org_name: (author.author_org_name || ''),
          author_email: (author.author_email || ''),
          id: (author.id),
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values);
        setSubmitting(false);
      }}
      validateOnChange={false}
    >
      {({handleSubmit, errors, touched}) => (
        <Form className="author-form">
          <Field name="id" type="hidden" />
          {author.author_org_name !== null ? (
            <div className="input-stack affiliation-input" style={{paddingBottom: '1ch'}}>
              <label className="input-label" htmlFor={`author_org_name__${author.id}`}>
                Organization or group name
              </label>
              <Field
                id={`author_org_name__${author.id}`}
                name="author_org_name"
                type="text"
                className="c-input__text"
                aria-errormessage="author_fname_error"
                aria-describedby={`${author.id}org-ex`}
                onBlur={handleSubmit}
              />
              <div id={`${author.id}org-ex`}><i />Committee, agency, working group, etc.</div>
            </div>
          ) : (
            <>
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
                  aria-describedby={`${author.id}name-ex`}
                  onBlur={handleSubmit}
                />
                <div id={`${author.id}name-ex`}><i />Given name</div>
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
                  aria-describedby={`${author.id}lname-ex`}
                  onBlur={handleSubmit}
                />
                <div id={`${author.id}lname-ex`}><i />Family name</div>
              </div>
              <div className="input-stack">
                <div
                  className="input-line"
                  style={{
                    gap: '1ch', justifyContent: 'space-between', alignItems: 'baseline', flexWrap: 'nowrap',
                  }}
                >
                  <label className={`input-label ${(author.author_orcid ? 'required' : '')}`} htmlFor={`author_email__${author.id}`}>
                    Email
                  </label>
                  <span className="radio_choice" style={{fontSize: '.98rem'}}>
                    <label title={author.author_email ? null : 'Author email must be entered'}>
                      <input
                        type="checkbox"
                        defaultChecked={author.corresp}
                        disabled={!author.author_email}
                        aria-errormessage="author_corresp_error"
                        onChange={(e) => update({...author, corresp: e.target.checked})}
                      />
                      Corresponding
                    </label>
                  </span>
                </div>
                <Field
                  id={`author_email__${author.id}`}
                  name="author_email"
                  type="text"
                  className="c-input__text"
                  aria-errormessage="author_email_error"
                  aria-describedby={`${author.id}email-ex`}
                  validate={validateEmail}
                  onBlur={handleSubmit}
                />
                {errors.author_email && touched.author_email && <span className="c-ac__error_message">{errors.author_email}</span>}
                <div id={`${author.id}email-ex`}><i />name@institution.org</div>
              </div>
              <Affiliations formRef={formRef} id={author.id} affiliations={affiliations} setAffiliations={setAffiliations} />
              <div className="input-line" style={{flexBasis: '100%', maxWidth: '100%', marginTop: '.5em'}}>
                <OrcidInfo author={author} curator={admin} ownerId={ownerId} />
              </div>
            </>
          )}
        </Form>
      )}
    </Formik>
  );
}

AuthorForm.propTypes = {
  author: PropTypes.object.isRequired,
  update: PropTypes.func.isRequired,
  admin: PropTypes.bool.isRequired,
  ownerId: PropTypes.number.isRequired,
};
