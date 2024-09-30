import React, {useRef, useState, useEffect} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function ResearchDomain({resource, setResource}) {
  const formRef = useRef();
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const subject = resource.subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
  const [subjectList, setSubjectList] = useState([]);

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/fos_subjects').then((data) => {
        setSubjectList(data.data);
      });
    }
    getList();
  }, []);

  return (
    <Formik
      initialValues={{fos_subjects: (subject || '')}}
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        showSavingMsg();
        axios.patch(
          '/stash_datacite/fos_subjects/update',
          {
            authenticity_token,
            fos_subjects: values.fos_subjects,
            id: resource.id,
          },
          {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
        )
          .then((data) => {
            if (data.status !== 200) {
              // console.log('Response failure not a 200 response');
            }
            showSavedMsg();
            setResource((r) => {
              const sub = r.subjects.filter((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
              r.subjects = [values.fos_subjects, ...sub];
              return r;
            });
            setSubmitting(false);
          });
      }}
    >
      {(formik) => (
        <Form className="c-input" id={`dc_fos_subjects_${resource.id}`}>
          <label className="c-input__label required" htmlFor={`fos_subjects__${resource.id}`}>
            Research domain
          </label>
          <Field
            type="text"
            name="fos_subjects"
            id={`fos_subjects__${resource.id}`}
            list={`fos_subject__${resource.id}`}
            className="fos-subjects js-change-submit c-input__text"
            onBlur={() => { // formRef.current.handleSubmit();
              formik.handleSubmit();
            }}
          />
          <datalist id={`fos_subject__${resource.id}`} className="c-input__text">
            {subjectList.map((subj, index) => {
              // key made from subj + count of preceding duplicates
              const key = subj + subjectList.slice(0, index).filter((s) => s === subj).length;
              return <option value={subj} key={key}>{subj}</option>;
            })}
          </datalist>
        </Form>
      )}
    </Formik>
  );
}

export default ResearchDomain;

ResearchDomain.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
