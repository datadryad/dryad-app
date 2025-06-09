import React, {useEffect, useState} from 'react';
import axios from 'axios';
import {truncate} from 'lodash';
import Autocomplete from '../Autocomplete';

export default function Manuscript({
  formRef, msid, setMSID, jid, controlOptions,
}) {
  const [acText, setAcText] = useState(msid);
  const [prevMSID, setPrevMSID] = useState(msid);
  const [autoBlurred, setAutoBlurred] = useState(false);

  useEffect(() => {
    if (autoBlurred) {
      if (!acText) {
        setMSID(null);
      } else if (!msid) {
        setMSID(acText);
      }
      if (msid !== prevMSID) {
        formRef.current.values.isImport = false;
        formRef.current.handleSubmit();
        setPrevMSID(msid);
        setAutoBlurred(false);
      }
    }
  }, [autoBlurred, msid]);

  const supplyLookupList = (qt) => axios.get(
    '/stash_datacite/publications/automsid',
    {
      params: {term: qt, jid},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    },
  )
    .then((data) => {
      if (data.status !== 200) {
        return [];
      }

      const list = data.data.map((i) => {
        i.display = (
          <>
            {i.id}<br />
            <small>{truncate(i.title, {length: 35})} {i.authors.length > 0 && `(${i.authors.map((a) => a.family_name).join(', ')}) `}</small>
          </>
        );
        return i;
      });
      return list;
    });

  const nameFunc = (item) => (item?.id || '');
  const idFunc = (item) => item.id;

  return (
    <Autocomplete
      acText={acText || ''}
      setAcText={setAcText}
      acID={msid || ''}
      setAcID={setMSID}
      setAutoBlurred={setAutoBlurred}
      supplyLookupList={supplyLookupList}
      nameFunc={nameFunc}
      idFunc={idFunc}
      controlOptions={controlOptions}
    />
  );
}
