import React, {useEffect, useState} from 'react';
import axios from 'axios';
import stringSimilarity from 'string-similarity';
import Autocomplete from '../Autocomplete';

export default function Journal({
  formRef, title, setTitle, issn, setIssn, setHideImport, controlOptions,
}) {
  const [prevTitle, setPrevTitle] = useState(title);
  const [prevISSN, setPrevISSN] = useState(issn);
  const [autoBlurred, setAutoBlurred] = useState(false);
  const [api_journals, setAPIJournals] = useState([]);

  useEffect(() => {
    if (issn) {
      if (api_journals.includes(issn)) setHideImport(true);
    }
  }, [issn, api_journals]);

  useEffect(() => {
    if (autoBlurred) {
      if (!title) {
        setIssn('');
      }
      if (prevTitle !== title || prevISSN !== issn) {
        formRef.current.values.isImport = false;
        formRef.current.handleSubmit();
      }
      setPrevTitle(title);
      setPrevISSN(issn);
      setAutoBlurred(false);
    }
  }, [autoBlurred]);

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/publications/api_list').then((data) => {
        setAPIJournals(data.data.api_journals);
      });
    }
    getList();
  }, []);

  const supplyLookupList = (qt) => axios.get('/stash_datacite/publications/autocomplete', {
    params: {term: qt},
    headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
  })
    .then((data) => {
      if (data.status !== 200) {
        return [];
      }
      // remove duplicates of the same name
      const deduped = {};
      data.data.forEach((item) => {
        // only add to the deduped key/value if the key doesn't exist
        if (!deduped[item.title]) {
          deduped[item.title] = item;
        }
      });

      const list = Object.values(deduped).map((item) => {
        // add one point if starts with the same string, sends to top
        const similarity = stringSimilarity.compareTwoStrings(item.title, qt) + (item.title.startsWith(qt) ? 1 : 0);
        return {...item, similarity};
      });
      list.sort((x, y) => ((x.similarity < y.similarity) ? 1 : -1));
      return list;
    });

  const nameFunc = (item) => (item?.title || '');
  const idFunc = (item) => item.issn;

  return (
    <Autocomplete
      acText={title || ''}
      setAcText={setTitle}
      acID={issn || ''}
      setAcID={setIssn}
      setAutoBlurred={setAutoBlurred}
      supplyLookupList={supplyLookupList}
      nameFunc={nameFunc}
      idFunc={idFunc}
      controlOptions={controlOptions}
    />
  );
}
