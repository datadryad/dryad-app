import React, {useState, useEffect} from 'react';
import axios from 'axios';
import Autocomplete from '../Autocomplete';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function FundingSearch({contributor, updateFunder}) {
  const [grantnum, setGrantnum] = useState(contributor.award_number || '');
  const [autoBlurred, setAutoBlurred] = useState(false);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const setFundingFromSearch = (fields) => {
    if (fields) {
      try {
        showSavingMsg();
        const contrib = JSON.parse(fields);
        contrib.identifier_type = 'ror';
        contrib.resource_id = contributor.resource_id;
        contrib.id = contributor.id;
        return axios.patch(
          '/stash_datacite/contributors/update',
          {authenticity_token, contributor: contrib},
          {
            headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
          },
        ).then((data) => {
          if (data.data.name_identifier_id === contributor.name_identifier_id && contributor.group_required) data.data.group_required = true;
          updateFunder(data.data);
          showSavedMsg();
        });
      } catch (e) {
        console.log(e);
        return false;
      }
    }
    return false;
  };

  const supplyLookupList = (qt) => axios.get(
    '/stash_datacite/awards/autocomplete',
    {
      params: {name_identifier_id: contributor.name_identifier_id, award_number: qt},
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    },
  )
    .then((data) => {
      if (!data.data.success) {
        return [];
      }
      const list = data.data.awards.map((a) => {
        a.display = (<>{a.award_number}<br /><small>{a.award_title}<br />{a.contributor_name}</small></>);
        return a;
      });
      return list;
    });

  const nameFunc = (item) => (item?.award_number || '');
  const idFunc = (item) => JSON.stringify(item);

  useEffect(() => {
    if (autoBlurred) {
      setFundingFromSearch(JSON.stringify({
        contributor_name: contributor.contributor_name,
        name_identifier_id: contributor.name_identifier_id,
        award_number: grantnum,
      }));
      setAutoBlurred(false);
    }
  }, [autoBlurred]);

  return (
    <div className="input-stack">
      <Autocomplete
        acText={grantnum}
        setAcText={setGrantnum}
        acID={grantnum}
        setAcID={setFundingFromSearch}
        setAutoBlurred={setAutoBlurred}
        supplyLookupList={supplyLookupList}
        nameFunc={nameFunc}
        idFunc={idFunc}
        controlOptions={
          {
            labelText: 'Search by award number',
            htmlId: `award_lookup_${contributor.id}`,
            desBy: `${contributor.id}award-ex`,
          }
        }
      />
      <div id={`${contributor.id}award-ex`}><i aria-hidden="true" />{contributor.api_integration_key === 'NSF' ? '1234567' : 'U54AB123456'}</div>
    </div>
  );
}

export default FundingSearch;
