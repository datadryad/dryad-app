import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import SubjectSelect from './SubjectSelect';
import KeywordAutocomplete from './KeywordAutocomplete';

function Keywords({resource, setResource}) {
  const subjects = resource.subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
  const [subjs, setSubjs] = useState(subjects);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const saveKeyword = (strKeyword) => {
    // the controller for this is a bit weird since it may accept one keyword or multiple separated by commas and it returns
    // the full list of keywords again after adding one or more
    if(strKeyword === '') return;

    showSavingMsg();
    axios.post(
      '/stash_datacite/subjects/create',
      {authenticity_token, subject: strKeyword, resource_id: resource.id},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status !== 200) {
        return [];
        // raise an error here if we want to catch it and display something to user or do something else
      }
      setSubjs(data.data);
      showSavedMsg();
      return data.data;
    });
  };

  const deleteKeyword = (id) => {
    showSavingMsg();
    axios.delete(`/stash_datacite/subjects/${id}/delete`, {
      data: {authenticity_token, resource_id: resource.id},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        return;
      }
      showSavedMsg();
      // removes the item we just deleted from the list based on id
      setSubjs(subjs.filter((item) => (item.id !== data.data.id)));
    });
  };

  useEffect(() => {
    setResource((r) => ({...r, subjects: [...r.subjects.filter((s) => ['fos', 'bad_fos'].includes(s.subject_scheme)), ...subjs]}));
  }, [subjs]);

  return (
    <SubjectSelect
      selected={subjs}
      id="keyword_ac"
      label={<>Subject keywords<span className="details">(at least 3)</span></>}
      example={(
        <div id="keywords-ex">
          <i aria-hidden="true" />Other research domains, scientific names, method types, or keywords from your related article
        </div>
      )}
      remove={deleteKeyword}
    >
      <KeywordAutocomplete
        id=""
        name=""
        saveFunction={saveKeyword}
        controlOptions={
          {
            htmlId: 'keyword_ac',
            labelText: '',
            isRequired: false,
            saveOnEnter: true,
            errorId: 'subj_error',
            desBy: 'keywords-ex',
          }
        }
      />
    </SubjectSelect>
  );
}

export default Keywords;

Keywords.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
