import React, {useState, useRef, useEffect} from 'react';
import {Form, Formik} from 'formik';
import {useStore} from '../../../shared/store';
import RorAutocomplete from '../RorAutocomplete';
import OrcidInfo from './OrcidInfo';
 
const fullname = (author) => [author?.author_org_name, author?.author_first_name, author?.author_last_name].filter(Boolean).join(' ');

function AffiliationsForm({author, updateItem}) {
  const {updateStore} = useStore();
  const formRef = useRef();
  const id = author.id;
  const [affiliations, setAffiliations] = useState(author.affiliations.length > 0 ? author.affiliations : [{long_name: '', ror_id: ''}]);

  const submitForm = async () => {
    const a = structuredClone(author)
    a.affiliations = affiliations
    await updateItem(a)
    updateStore({refreshFees: true});
  }

  useEffect(() => {
    if (formRef.current && affiliations !== author.affiliations) {
      submitForm()
    }
  }, [affiliations, formRef]);

  const updateName = (i, v) => {
    setAffiliations((afs) => afs.map((a, x) => (i === x ? {...a, long_name: v} : a)));
  };
  const updateID = (i, v) => {
    setAffiliations((afs) => afs.map((a, x) => (i === x ? {...a, ror_id: v} : a)));
  };
  const newAff = (e) => {
    setAffiliations((afs) => afs.concat([{long_name: '', ror_id: ''}]));
    e.target.blur();
  };
  const removeAff = (index) => {
    setAffiliations((afs) => afs.filter((a, i) => i !== index));
  };

  return (
    <Formik
      innerRef={formRef}
      onSubmit={(_v, {setSubmitting}) => {
        submitForm();
        setSubmitting(false);
      }}
      initialValues={{}}
      validateOnChange={false}
    >
      {() => (
        <Form className="author-form">
          {affiliations.map((aff, i) => (
            <div className="input-stack affiliation-input" key={`aff${i}`}>
              <div className="input-line">
                <label id={`label_instit_affil_${id}-${i}`} htmlFor={`instit_affil_${id}-${i}`} className="input-label">
                  Institutional affiliation
                </label>
                {i !== 0 && (
                  <button type="button" aria-label={`Remove affiliation ${aff.long_name}`} title="Remove affiliation" onClick={() => removeAff(i)}>
                    <i className="fas fa-xmark" aria-hidden="true" />
                  </button>
                )}
              </div>
              <RorAutocomplete
                formRef={formRef}
                acText={aff.long_name || ''}
                setAcText={(v) => updateName(i, v)}
                acID={aff.ror_id || ''}
                setAcID={(v) => updateID(i, v)}
                controlOptions={{
                  htmlId: `instit_affil_${id}-${i}`,
                  isRequired: true,
                  errorId: 'author_aff_error',
                  desBy: `${id}-${`aff${i}`}-ex`,
                  autoComplete: 'organization',
                }}
              />
              <div id={`${id}-${`aff${i}`}-ex`}><i aria-hidden="true" />Employer or sponsor</div>
            </div>
          ))}
          <div className="author-one-line"><button type="button" className="add-aff-button" onClick={newAff}>+ Add affiliation</button></div>
        </Form>
      )}
    </Formik>
  );
}

export default function Affiliations({authors, updateItem}) {
  return (
    authors.map(author => {
      if(author.author_org_name) {
        return (
          <div className="author-form aff-form" key={author.id}>
            {fullname(author)}
          </div>
        )
      }
      return (
        <div className="author-form aff-form" key={author.id}>
          <div className="input-line">
            {fullname(author)}
            <OrcidInfo author={author} curator={false} />
          </div>
          <AffiliationsForm {...{author, updateItem}}/>
        </div>
      )
    })
  )
}
