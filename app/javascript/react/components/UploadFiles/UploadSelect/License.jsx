import React, {useEffect, useRef} from 'react';
import axios from 'axios';

export default function License({license, resourceId, setResource}) {
  const divRef = useRef(null);

  const submit = () => {
    const {value} = document.getElementById('searchselect-license__value');
    axios.post(
      '/stash/software_license',
      {resource_id: resourceId, license: value},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      setResource((r) => ({...r, identifier: {software_license: data.data, ...r.identifier}}));
    });
  };

  useEffect(() => {
    async function getList() {
      axios.get(`/stash/software_license_select?select=${license?.id || ''}`).then((data) => {
        const active_form = document.createRange().createContextualFragment(data.data);
        divRef.current.append(active_form);
        document.getElementById('searchselect-license__input').addEventListener('blur', submit);
        submit();
      });
    }
    if (divRef.current) getList();
  }, [divRef]);

  return (
    <div className="license-select" ref={divRef} />
  );
}
