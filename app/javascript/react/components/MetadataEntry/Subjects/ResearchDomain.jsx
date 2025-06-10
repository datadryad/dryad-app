import React, {useRef, useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function ResearchDomain({step, resource, setResource}) {
  const fieldRef = useRef(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const [subject, setSubject] = useState(resource.subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme))?.subject);
  const [subjects, setSubjects] = useState([]);

  const submit = (e) => {
    setSubject(e.target.value);
    showSavingMsg();
    axios.patch(
      '/stash_datacite/fos_subjects/update',
      {
        authenticity_token,
        fos_subjects: e.target.value,
        id: resource.id,
      },
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status === 200) {
        // console.log('Response failure not a 200 response');
        }
        showSavedMsg();
        setResource((r) => ({
          ...r,
          subjects: [
            ...data.data,
            ...r.subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme)),
          ],
        }));
      });
  };

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/fos_subjects').then((data) => {
        setSubjects(data.data);
      });
    }
    if (fieldRef.current && step === 'Subjects') getList();
  }, [fieldRef, step]);

  return (
    <form className="input-stack" style={{marginBottom: '1.5em'}}>
      <label htmlFor="r_domain">Research domain</label>
      <select ref={fieldRef} id="r_domain" aria-errormessage="domain_error" className="c-input__select" onChange={submit} value={subject}>
        <option value="" aria-label="Select a Research domain" />
        {subjects.map((s) => <option key={s} value={s}>{s}</option>)}
      </select>
      <div className="input-example"><i aria-hidden="true" />The main scholarly or technical field for the data or project</div>
    </form>
  );
}

export default ResearchDomain;

ResearchDomain.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
