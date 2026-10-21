import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {xor} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import SubjectSelect from './SubjectSelect';

function ResearchDomain({
  current, resource, setResource, onBlur,
}) {
  const domains = resource.subjects?.filter((s) => ['fos', 'bad_fos'].includes(s.subject_scheme)).map((s) => s.subject);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const [selected, setSelected] = useState(domains || []);
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
        if (data.status !== 200) {
          console.log('Response failure not a 200 response');
        }
        showSavedMsg();
        setResource((r) => ({...r, subjects: data.data}));
      });
  };

  useEffect(() => {
    if (xor(domains, selected).length) {
      submit(selected);
    }
  }, [selected]);

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/fos_subjects').then(({data}) => {
        setSubjects(data)
      });
    }
    if (subjects.length < 1) getList()
  }, [current, subjects]);

  return (
    <form className="input-stack" style={{marginBottom: '1.5em'}}>
      <SubjectSelect
        selected={selected}
        id="r_domain"
        label="Research domains"
        example={<div id="r_domain-ex"><i aria-hidden="true" />The main scholarly or technical fields for the data or project</div>}
        remove={(subj) => setSelected((s) => s.filter((k) => k !== subj))}
      >
        {subjects.length > 0 && (
          <select
            id="r_domain"
            aria-describedby="r_domain-ex"
            aria-errormessage="domain_error"
            className="c-input__select"
            onChange={(e) => setSelected((s) => s.concat(e.target.value))}
            onBlur={onBlur}
          >
            <option value="">Select Research domain</option>
            {subjects.filter((s) => !selected.includes(s)).map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
        )}
      </SubjectSelect>
    </form>
  );
}

export default ResearchDomain;