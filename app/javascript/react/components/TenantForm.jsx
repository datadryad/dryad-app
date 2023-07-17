import React, {useRef, useState} from 'react';
import axios from 'axios';
import {Form, Formik} from 'formik';
import PropTypes from 'prop-types';
import GenericNameIdAutocomplete from './MetadataEntry/GenericNameIdAutocomplete';

// the autocomplete name, autocomplete id (like ROR), get/set autocomplete Text, get/set autocomplete ID
export default function TenantForm({tenants, postPath}) {
  const formRef = useRef(0);
  // in order to use this component, we need to track the state of the autocomplete text and the autocomplete id
  // https://www.freecodecamp.org/news/what-is-lifting-state-up-in-react/ is a better functional example than the react docs.
  // also tracking "autoBlurred" since we need to know when things exit to trigger form resubmission or sending to server.
  const [acText, setAcText] = useState('');
  const [acID, setAcID] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const nameFunc = (item) => item.name;
  const idFunc = (item) => item.id;

  const submitForm = () => {
    console.log(`${(new Date()).toISOString()}: Setting Tenant`);
    // set up values
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {authenticity_token, tenant_id: acID, commit: 'Login+to+verify'};

    // submit by json
    return axios.post(
      postPath,
      submitVals,
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Accept: 'application/json',
        },
      },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from tenant save');
      }
      const {data: {redirect, alert}} = data;
      if (redirect) window.location = redirect;
      if (alert) setError(alert);
    });
  };

  const supplyLookupList = (qt) => new Promise((resolve) => {
    if (qt.length > 0) {
      console.log(qt);
      const lcqt = qt.toLowerCase();
      resolve(tenants.filter((t) => t.name.toLowerCase().includes(lcqt)));
    } else {
      resolve(tenants);
    }
  });

  return (
    <>
      <Formik
        initialValues={{}}
        innerRef={formRef}
        onSubmit={(values, {setSubmitting}) => {
          setLoading(true);
          submitForm(values).then(() => { setSubmitting(false); });
        }}
      >
        {(formik) => (
          <Form className="c-input__inline" onSubmit={() => formik.handleSubmit()}>
            {loading ? (
              <img
                alt="Loading..."
                src="/assets/stash_engine/spinner-47c716a105894b5888f62cfa3108a66830f958e41247c4396d70a57821464ffa.gif"
                style={{height: '60px'}}
              />
            )
              : (
                <>
                  <GenericNameIdAutocomplete
                    acText={acText || ''}
                    setAcText={setAcText}
                    acID={acID}
                    setAcID={setAcID}
                    supplyLookupList={supplyLookupList}
                    nameFunc={nameFunc}
                    idFunc={idFunc}
                    controlOptions={{htmlId: 'tenant_lookup', labelText: '', showDropdown: true}}
                    setAutoBlurred={() => false}
                  />
                  <button type="submit" className="t-login__buttonlink">Login to verify</button>
                </>
              )}
          </Form>
        )}
      </Formik>
      {error && <span className="c-ac__error_message" id="error_tenant_lookup">{error}</span>}
    </>
  );
}

TenantForm.propTypes = {
  tenants: PropTypes.array.isRequired,
  postPath: PropTypes.string.isRequired,
};
