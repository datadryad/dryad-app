import React, {useEffect, useRef, useState} from 'react';
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import RorAutocomplete from '../RorAutocomplete';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function FunderForm({
  current, resourceId, contributor, updateFunder,
}) {
  const formRef = useRef();
  const [acText, setAcText] = useState('');
  const [loading, setLoading] = useState(true);
  const [showSelect, setShowSelect] = useState(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const setValues = () => ({
    contributor_name: (contributor.contributor_name || ''),
    name_identifier_id: (contributor.name_identifier_id || ''),
    award_description: (contributor.award_description || ''),
    award_title: (contributor.award_title || ''),
    award_number: (contributor.award_number || ''),
    id: (contributor.id || ''),
  });

  const subSelect = (e) => {
    const select = e.target;
    setAcText(select.selectedOptions[0].text);
    formRef.current.values.name_identifier_id = select.value;
    formRef.current.values.contributor_name = select.selectedOptions[0].text;
    formRef.current.handleSubmit();
    setShowSelect(null);
  };

  const submitForm = (values) => {
    showSavingMsg();
    const submitVals = {
      authenticity_token,
      contributor: {
        id: values.id,
        contributor_name: values.contributor_name,
        contributor_type: 'funder',
        identifier_type: 'ror',
        name_identifier_id: values.name_identifier_id,
        award_number: values.award_number,
        award_description: values.award_description,
        award_title: values.award_title,
        resource_id: resourceId,
      },
    };

    return axios.patch(
      '/stash_datacite/contributors/update',
      submitVals,
      {
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
      },
    ).then((data) => {
      if (data.data.name_identifier_id === contributor.name_identifier_id && contributor.group_required) data.data.group_required = true;
      updateFunder(data.data);
      showSavedMsg();
    }).catch((err) => {
      [...document.querySelectorAll('.saving_text')].forEach((el) => el.setAttribute('hidden', true));
      Object.entries(err.response.data).forEach((e) => {
        formRef.current.setFieldError(e[0], e[1][0]);
      });
    });
  };

  useEffect(() => {
    if (current) {
      formRef.current?.resetForm({values: setValues()});
      setAcText(contributor.contributor_name || '');
      setLoading(false);
    }
  }, [current, contributor]);

  useEffect(() => {
    async function getGroup() {
      axios.post('/stash_datacite/contributors/grouping', {
        authenticity_token,
        ror_id: contributor.name_identifier_id,
      }).then((data) => {
        setShowSelect(data.data);
        if (data.data?.required) updateFunder({...contributor, group_required: true});
      });
    }
    if (contributor.name_identifier_id) getGroup();
  }, [contributor.name_identifier_id]);

  const jsonOptions = () => {
    if (!showSelect || !showSelect.json_contains) return null;

    return showSelect.json_contains.map((i) => <option key={i.name_identifier_id} value={i.name_identifier_id}>{i.contributor_name}</option>);
  };
  return (
    <Formik
      initialValues={setValues()}
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="funder-form">
          <Field name="id" type="hidden" />
          {!loading && (
            <div className="input-stack">
              <RorAutocomplete
                formRef={formRef}
                acText={acText}
                setAcText={(v) => {
                  formik.setFieldValue('contributor_name', v);
                  setAcText(v);
                }}
                acID={formik.values.name_identifier_id}
                setAcID={(v) => formik.setFieldValue('name_identifier_id', v)}
                controlOptions={
                  {
                    htmlId: `contrib_${contributor.id}`,
                    labelText: 'Granting organization',
                    isRequired: true,
                    errorId: 'funder_error',
                    desBy: `${contributor.id}funder-ex`,
                  }
                }
              />
              <div id={`${contributor.id}funder-ex`}><i aria-hidden="true" />National Institutes of Health</div>
            </div>
          )}
          {showSelect && (
            <div className="input-stack">
              <label htmlFor="subfunder_select" className="input-label">{showSelect.group_label}</label>
              <select
                id="subfunder_select"
                className="c-input__select"
                onChange={subSelect}
                aria-errormessage={showSelect.required ? 'funder_group_error' : null}
              >
                <option value="">Select {showSelect.group_label}</option>
                {jsonOptions()}
              </select>
            </div>
          )}
          <div className="input-stack">
            <label className="input-label optional" htmlFor={`contributor_award_number__${contributor.id}`}>Award number
            </label>
            <Field
              id={`contributor_award_number__${contributor.id}`}
              name="award_number"
              type="text"
              className="js-award_number c-input__text"
              aria-describedby={`${contributor.id}award-ex`}
              aria-invalid={!!formik.errors.award_number || null}
              aria-errormessage={`contributor_errors__${contributor.id}`}
              onBlur={formik.handleSubmit}
            />
            <div id={`${contributor.id}award-ex`}><i aria-hidden="true" />CA 123456-01A1</div>
          </div>
          <div className="input-stack">
            <label className="input-label optional" htmlFor={`contributor_award_description__${contributor.id}`}>Program/division
            </label>
            <Field
              id={`contributor_award_description__${contributor.id}`}
              name="award_description"
              type="text"
              className="js-award_description c-input__text"
              aria-describedby={`${contributor.id}desc-ex`}
              aria-invalid={!!formik.errors.award_description || null}
              aria-errormessage={`contributor_errors__${contributor.id}`}
              onBlur={formik.handleSubmit}
            />
            <div id={`${contributor.id}desc-ex`}><i aria-hidden="true" />Awarding organization subdivision or program</div>
          </div>
          <div className="input-stack" style={{flexBasis: '100%'}}>
            <label className="input-label optional" htmlFor={`contributor_award_title__${contributor.id}`}>Award title
            </label>
            <Field
              id={`contributor_award_title__${contributor.id}`}
              name="award_title"
              type="text"
              className="js-award_description c-input__text"
              aria-describedby={`${contributor.id}title-ex`}
              aria-invalid={!!formik.errors.award_title || null}
              aria-errormessage={`contributor_errors__${contributor.id}`}
              onBlur={formik.handleSubmit}
            />
            <div id={`${contributor.id}title-ex`}><i aria-hidden="true" />Title of the award (grant, fellowship, etc.)</div>
          </div>
          {(!!formik.errors.award_number || !!formik.errors.award_description || !!formik.errors.award_title) && (
            <div id={`contributor_errors__${contributor.id}`} style={{color: '#d12c1d'}}>
              {Object.entries(formik.errors).map((arr) => <p key={arr[0]}>{arr[1]}</p>)}
            </div>
          )}
        </Form>
      )}
    </Formik>
  );
}

export default FunderForm;
