import React, {useEffect, useRef} from 'react';
import axios from 'axios';
import {showSavingMsg, showSavedMsg} from '../../../../lib/utils';

export default function License({
  current, license, resourceId, setResource,
}) {
  const divRef = useRef(null);

  const submit = () => {
    showSavingMsg();
    const {value} = document.getElementById('searchselect-license__value');
    axios.post(
      '/software_license',
      {resource_id: resourceId, license: value},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      setResource((r) => ({...r, identifier: {software_license: data.data, ...r.identifier}}));
      showSavedMsg();
    });
  };

  useEffect(() => {
    async function getList() {
      axios.get(`/software_license_select?select=${license?.id || ''}`).then((data) => {
        if (divRef.current) {
          const active_form = document.createRange().createContextualFragment(data.data);
          divRef.current.append(active_form);
          document.getElementById('searchselect-license__input').addEventListener('blur', submit);
          submit();
        }
      });
    }
    if (current && divRef.current) getList();
  }, [divRef, current]);

  return (
    <div className="license-select" ref={divRef} />
  );
}
