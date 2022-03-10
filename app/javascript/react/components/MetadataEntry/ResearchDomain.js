import React, {useRef} from 'react';
// see https://formik.org/docs/tutorial for basic tutorial, yup is easy default for validation w/ formik
import {Field, Form, Formik} from 'formik';
import {makeId, showSavingMsg} from '../../../lib/utils';

function ResearchDomain({resourceId, subject, subjectList, updatePath}) {

  const frmSuffix = makeId(resourceId);

  const formRef = useRef();

  /*
  Submits a hash like this in rails
  {
    "utf8"=>"✓",
    "authenticity_token"=>"fOwjAi3LKrxjnc+ziC5y56XtS2G0FMvpxiyCebdvwEl9YGD/DQY3b/Uv48tlf0dNkt10eVapY6ha4dKQ+z0wBg==",
    "fos_subjects"=>"Agricultural biotechnology",
    "id"=>"3589",
    "form_id"=>"dc_fos_subjects_3589"
    }
   */

  return (
      <Formik
          initialValues={{fos_subject: subject}}
          innerRef={formRef}
          onSubmit={(values, {setSubmitting}) => {
            showSavingMsg();
            // other stuff here for saving
          }}
      >{(formik) => (
        <Form className="c-input" id={`dc_fos_subjects_${frmSuffix}`}>
          <label className="c-input__label required" htmlFor={`fos_subjects__${frmSuffix}`}>Research Domain</label>
          <Field type="text" name="fos_subject" id={`fos_subjects__${frmSuffix}`} list={`fos_subject__${frmSuffix}`}
              className="fos-subjects js-change-submit c-input__text" />

          <datalist id={`fos_subject__${frmSuffix}`} className="c-input__text">
            {subjectList.map((subj) => (
                <option value={subj}>{subj}</option>
            ))}
          </datalist>
        </Form>
      )}
      </Formik>
  );
}

export default ResearchDomain;