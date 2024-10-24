import React, {useRef, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function ResearchDomain({resource, setResource}) {
  const fieldRef = useRef(null);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const subject = resource.subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));

  const submit = (e) => {
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
      axios.get(`/stash_datacite/fos_subjects?select=${subject?.subject ? encodeURI(subject.subject) : ''}`).then((data) => {
        const active_form = document.createRange().createContextualFragment(data.data);
        fieldRef.current.append(active_form);
        document.getElementById('searchselect-fos_subjects__input').setAttribute('aria-errormessage', 'domain_error');
        document.getElementById('searchselect-fos_subjects__input').addEventListener('blur', submit);
        document.querySelector("label[for='searchselect-fos_subjects__input']").classList.add('input-label');
      });
    }
    if (fieldRef.current) getList();
  }, [fieldRef]);

  return (
    <form className="input-stack" style={{marginBottom: '1.5em'}}>
      <div ref={fieldRef} />
      <div className="input-example"><i className="ie" />The main scholarly or technical field for the data or project</div>
    </form>
  );
}

export default ResearchDomain;

ResearchDomain.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
