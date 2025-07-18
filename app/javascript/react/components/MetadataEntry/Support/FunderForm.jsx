import React, {useEffect, useRef, useState} from 'react';
import {Field, Form, Formik} from 'formik';
import axios from 'axios';
import PropTypes from 'prop-types';
import RorAutocomplete from '../RorAutocomplete';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function FunderForm({resourceId, contributor, updateFunder}) {
  const formRef = useRef();
  const [acText, setAcText] = useState(contributor.contributor_name || '');
  const [acID, setAcID] = useState(contributor.name_identifier_id || '');
  const [showSelect, setShowSelect] = useState(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const subSelect = (e) => {
    const select = e.target;
    setAcID(select.value);
    setAcText(select.selectedOptions[0].text);
    formRef.current.handleSubmit();
    setShowSelect(null);
  };

  const submitForm = (values) => {
    showSavingMsg();
    const submitVals = {
      authenticity_token,
      contributor: {
        id: values.id,
        contributor_name: acText,
        contributor_type: 'funder',
        identifier_type: acID.includes('ror.org') ? 'ror' : 'crossref_funder_id',
        name_identifier_id: acID,
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
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from funders save');
      }
      updateFunder(data.data);
      showSavedMsg();
    });
  };

  useEffect(() => {
    async function getGroup() {
      axios.post('/stash_datacite/contributors/grouping', {
        authenticity_token,
        ror_id: acID,
      }).then((data) => {
        setShowSelect(data.data);
        if (data.data?.required) updateFunder({...contributor, group_required: true});
      });
    }
    if (acID) getGroup();
  }, [acID]);

  return (
    <Formik
      initialValues={
        {
          award_description: (contributor.award_description || ''),
          award_title: (contributor.award_title || ''),
          award_number: (contributor.award_number || ''),
          id: (contributor.id || ''),
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="funder-form">
          <Field name="id" type="hidden" />
          <div className="input-stack">
            <RorAutocomplete
              formRef={formRef}
              acText={acText}
              setAcText={setAcText}
              acID={acID}
              setAcID={setAcID}
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
                {showSelect.json_contains.map((i) => <option key={i.name_identifier_id} value={i.name_identifier_id}>{i.contributor_name}</option>)}
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
              onBlur={formik.handleSubmit}
            />
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
              onBlur={formik.handleSubmit}
            />
            <div id={`${contributor.id}title-ex`}><i aria-hidden="true" />Title of the grant awarded</div>
          </div>
        </Form>
      )}
    </Formik>
  );
}

export default FunderForm;

// resourceId, contributor, createPath, updatePath, removeFunction, updateFunder

FunderForm.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  contributor: PropTypes.object.isRequired,
  updateFunder: PropTypes.func.isRequired,
};
