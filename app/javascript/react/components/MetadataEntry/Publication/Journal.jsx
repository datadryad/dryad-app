import React, {useEffect, useState} from 'react';
import axios from 'axios';
import stringSimilarity from 'string-similarity';
import Autocomplete from '../Autocomplete';

export default function Journal({
  current, formRef, title, setTitle, issn, setIssn, setAPIJournal, controlOptions,
}) {
  const [prevTitle, setPrevTitle] = useState(`${title || ''}`);
  const [prevISSN, setPrevISSN] = useState(issn);
  const [autoBlurred, setAutoBlurred] = useState(false);
  const [api_journals, setAPIJournals] = useState([]);

  useEffect(() => {
    setAPIJournal(api_journals.includes(issn));
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
    if (current && !api_journals.length) getList();
  }, [current, api_journals]);

  const supplyLookupList = (qt) => axios.get(
    `/stash_datacite/publications/autocomplete${controlOptions?.labelText === 'Preprint server' ? '?preprint' : ''}`,
    {
      params: {term: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    },
  )
    .then((data) => {
      if (data.status !== 200) {
        return [];
      }
      const list = Object.values(data.data).map((item) => {
        // add one point if starts with the same string, sends to top
        const similarity = stringSimilarity.compareTwoStrings(item.title, qt) + (item.title.startsWith(qt) ? 1 : 0);
        return {...item, similarity};
      });
      list.sort((x, y) => ((x.similarity < y.similarity) ? 1 : -1));
      list.unshift({title: '', issn: '', id: ''});
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
