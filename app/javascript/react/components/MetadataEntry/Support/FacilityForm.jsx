import React, {useRef, useState} from 'react';
import axios from 'axios';
import {Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import RorAutocomplete from '../RorAutocomplete';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

export default function FacilityForm({resource, setResource}) {
  const formRef = useRef(null);
  const sponsor = resource.contributors.find((r) => r.contributor_type === 'sponsor') || {};
  const [name, setName] = useState(sponsor.contributor_name || '');
  const [nameId, setNameId] = useState(sponsor.name_identifier_id);

  const submitData = () => {
    showSavingMsg();
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const contributor = {
      resource_id: resource.id,
      identifier_type: 'ror',
      contributor_type: 'sponsor',
      contributor_name: name,
      name_identifier_id: nameId,
    };

    const method = sponsor.id ? 'patch' : 'post';
    const path = sponsor.id ? 'update' : 'create';
    if (sponsor.id) contributor.id = sponsor.id;

    return axios({
      method,
      url: `/stash_datacite/contributors/${path}`,
      data: {authenticity_token, contributor},
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        Accept: 'application/json',
      },
    }).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure from research facility save');
      }
      showSavedMsg();
      contributor.id = data.data.id;
      setResource((r) => ({...r, contributors: [contributor, ...r.contributors]}));
    });
  };

  return (
    <Formik
      initialValues={{}}
      innerRef={formRef}
      onSubmit={(_v, {setSubmitting}) => {
        submitData().then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="c-input" onSubmit={() => formik.handleSubmit()}>
          <RorAutocomplete
            formRef={formRef}
            acText={name || ''}
            setAcText={setName}
            acID={nameId || ''}
            setAcID={setNameId}
            controlOptions={{
              htmlId: 'research_facility',
              labelText: 'Research facility',
              isRequired: false,
              desBy: 'facility-ex',
            }}
          />
          <div id="facility-ex">
            <i aria-hidden="true" />A field or other station or organization where research was conducted, apart from affiliations
          </div>
        </Form>
      )}
    </Formik>
  );
  /* eslint-enable react/jsx-no-bind */
}

FacilityForm.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
