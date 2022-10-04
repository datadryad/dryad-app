import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import {makeId, showSavedMsg, showSavingMsg} from '../../../lib/utils';

function ResearchDomain({
  resourceId, subject, subjectList, updatePath,
}) {
  const frmSuffix = makeId(resourceId);
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const formRef = useRef();

  return (
    <Formik
      initialValues={{fos_subjects: (subject || '')}}
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        showSavingMsg();
        const vals = {
          authenticity_token: csrf,
          fos_subjects: values.fos_subjects,
          id: resourceId,
        };
        axios.patch(
          updatePath,
          vals,
          {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
        )
          .then((data) => {
            if (data.status !== 200) {
              // console.log('Response failure not a 200 response');
            }
            showSavedMsg();
            setSubmitting(false);
          });
      }}
    >
      {(formik) => (
        <Form className="c-input" id={`dc_fos_subjects_${frmSuffix}`}>
          <label className="c-input__label required" htmlFor={`fos_subjects__${frmSuffix}`}>
            Research Domain
          </label>
          <Field
            type="text"
            name="fos_subjects"
            id={`fos_subjects__${frmSuffix}`}
            list={`fos_subject__${frmSuffix}`}
            className="fos-subjects js-change-submit c-input__text"
            onBlur={() => { // formRef.current.handleSubmit();
              formik.handleSubmit();
            }}
          />

          {/* ok to use array index as key since list never changes */}
          {/* eslint-disable react/no-array-index-key */}
          <datalist id={`fos_subject__${frmSuffix}`} className="c-input__text">
            {subjectList.map((subj, idx) => (
              <option value={subj} key={idx}>{subj}</option>
            ))}
          </datalist>
          {/* eslint-enable react/no-array-index-key */}
        </Form>
      )}
    </Formik>
  );
}

export default ResearchDomain;

ResearchDomain.propTypes = {
  resourceId: PropTypes.number.isRequired,
  subject: PropTypes.string,
  subjectList: PropTypes.array.isRequired,
  updatePath: PropTypes.string.isRequired,
};
