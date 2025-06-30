import React, {useRef, useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {xor} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import SubjectSelect from './SubjectSelect';

function ResearchDomain({step, resource, setResource}) {
  const fieldRef = useRef(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const [selected, setSelected] = useState(
    resource.subjects?.filter((s) => ['fos', 'bad_fos'].includes(s.subject_scheme)).map((s) => s.subject) || [],
  );
  const [subjects, setSubjects] = useState([]);

  const submit = (items) => {
    showSavingMsg();
    axios.patch(
      '/stash_datacite/fos_subjects/update',
      {
        authenticity_token,
        fos_subjects: items,
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
    const oldSelected = resource.subjects?.filter((s) => ['fos', 'bad_fos'].includes(s.subject_scheme)).map((s) => s.subject) || [];
    if (xor(oldSelected, selected).length) {
      submit(selected);
    }
  }, [selected]);

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/fos_subjects').then((data) => {
        setSubjects(data.data);
      });
    }
    if (fieldRef.current && step === 'Subjects') getList();
  }, [fieldRef, step]);

  return (
    <form className="input-stack" ref={fieldRef} style={{marginBottom: '1.5em'}}>
      <SubjectSelect
        selected={selected}
        id="r_domain"
        label="Research domains"
        example={<div id="r_domain-ex"><i aria-hidden="true" />The main scholarly or technical fields for the data or project</div>}
        remove={(subj) => setSelected((s) => s.filter((k) => k !== subj))}
      >
        <select
          id="r_domain"
          aria-describedby="r_domain-ex"
          aria-errormessage="domain_error"
          className="c-input__select"
          onChange={(e) => setSelected((s) => s.concat(e.target.value))}
        >
          <option value="">Select Research domain</option>
          {subjects.filter((s) => !selected.includes(s)).map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
      </SubjectSelect>
    </form>
  );
}

export default ResearchDomain;

ResearchDomain.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
