import React, {useState, useEffect, useRef} from 'react';
import {Field, Form, Formik} from 'formik';
import Affiliations from './Affiliations';
import OrcidInfo from './OrcidInfo';
import Editor from './Editor';

export default function AuthorForm({
  author, users, update, invite, user,
}) {
  const formRef = useRef(0);
  const [affiliations, setAffiliations] = useState(author?.affiliations);
  const editor = author.author_orcid && users.find((u) => u.orcid === author.author_orcid);

  const submitForm = (values) => {
    const submit = {
      id: values.id,
      author_first_name: author.author_org_name !== null ? null : values.author_first_name,
      author_last_name: values.author_last_name,
      author_org_name: author.author_org_name !== null ? values.author_org_name : null,
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

  useEffect(() => {
    if (formRef.current && affiliations.length < author.affiliations.length) formRef.current.handleSubmit();
  }, [affiliations]);

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
              <div id={`${author.id}org-ex`}><i aria-hidden="true" />Committee, agency, working group, etc.</div>
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
                <div id={`${author.id}name-ex`}><i aria-hidden="true" />Given name</div>
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
                <div id={`${author.id}lname-ex`}><i aria-hidden="true" />Family name</div>
              </div>
              <Affiliations formRef={formRef} id={author.id} affiliations={affiliations} setAffiliations={setAffiliations} />
              <div className="author-form email-opts">
                <div className="input-stack">
                  <label className={`input-label ${(author.author_orcid ? 'required' : '')}`} htmlFor={`author_email__${author.id}`}>
                    Email address
                  </label>
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
                  <div id={`${author.id}email-ex`}><i aria-hidden="true" />name@institution.org</div>
                </div>
                <div className="input-stack author-one-line" style={{gap: '.5ch'}}>
                  <div className="radio_choice">
                    <label title={author.author_email ? null : 'Author email must be entered'}>
                      <input
                        type="checkbox"
                        defaultChecked={author.corresp}
                        disabled={!author.author_email}
                        aria-errormessage="author_corresp_error"
                        onChange={(e) => update({...author, corresp: e.target.checked})}
                      />
                      Publish email
                    </label>
                  </div>
                  <OrcidInfo author={author} curator={user.curator} />
                </div>
                <Editor user={user} author={author} editor={editor} users={users} invite={invite} />
              </div>
              {(editor && user.id === editor.id && author.author_email !== editor.email) && (
                <p style={{marginTop: 0, fontSize: '.98rem'}}>
                  You can update your email address for Dryad communications from <a href="/account">My account</a>
                </p>
              )}
            </>
          )}
        </Form>
      )}
    </Formik>
  );
}
