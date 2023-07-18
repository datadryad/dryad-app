import React, {useRef, useState} from 'react';
import axios from 'axios';
import {Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import RorAutocomplete from './RorAutocomplete';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export default function FacilityForm({
  name, rorId, contribId, resourceId, createPath, updatePath, controlOptions,
}) {
  const formRef = useRef(0);
  // control options: htmlId, labelText, isRequired (t/f)

  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs.
  // also tracking "autoBlurred" since we need to know when things exit to trigger form resubmission or sending to server.
  const [acText, setAcText] = useState(name);
  const [acID, setAcID] = useState(rorId);
  const [contributorId, setContributorId] = useState(contribId);
  const nameRef = useRef(null);

  const submitData = () => {
    showSavingMsg();
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

    const values = {
      authenticity_token,
      contributor: {
        id: contributorId,
        resource_id: resourceId,
        identifier_type: 'ror',
        contributor_type: 'sponsor',
        contributor_name: acText,
        name_identifier_id: acID,
      },
    };

    let url;
    let method;
    if (contributorId) {
      url = updatePath;
      method = 'patch';
    } else {
      url = createPath;
      method = 'post';
    }

    axios({
      method,
      url,
      data: values,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from research facility save');
      }
      setContributorId(data.data.id);
      showSavedMsg();
    });
  };

  return (
    <Formik
      initialValues={{}}
      innerRef={formRef}
      onSubmit={({setSubmitting}) => {
        submitData().then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form className="c-input" onSubmit={() => formik.handleSubmit()}>
          <RorAutocomplete
            formRef={formRef}
            acText={acText}
            setAcText={setAcText}
            acID={acID}
            setAcID={setAcID}
            controlOptions={controlOptions}
          />
          <input ref={nameRef} type="hidden" value={acText} className="js-affil-longname" name="contributor[name_identifier_id]" />
          <input type="hidden" value={acID} className="js-affil-id" name="author[affiliation][ror_id]" />
        </Form>
      )}
    </Formik>
  );
  /* eslint-enable react/jsx-no-bind */
}

// {name, rorId, contribId, resourceId, createPath, updatePath, controlOptions}
FacilityForm.propTypes = {
  name: PropTypes.string.isRequired,
  rorId: PropTypes.string.isRequired,
  contribId: PropTypes.number,
  resourceId: PropTypes.number.isRequired,
  createPath: PropTypes.string.isRequired,
  updatePath: PropTypes.string.isRequired,
  controlOptions: PropTypes.object.isRequired,
};

FacilityForm.defaultProps = {contribId: ''};
