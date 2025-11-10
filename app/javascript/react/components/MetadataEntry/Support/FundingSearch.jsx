import React, {useState, useEffect} from 'react';
import axios from 'axios';
import FunderForm from './FunderForm';
import Autocomplete from '../Autocomplete';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function FundingSearch({
  current, resource, contributor, disabled, updateFunder,
}) {
  const NIH = 'https://ror.org/01cwqze88';
  const NSF = 'https://ror.org/021nxhr62';
  const [search, setSearch] = useState(true);
  const [grantnum, setGrantnum] = useState(contributor.award_number || '');
  const [autoBlurred, setAutoBlurred] = useState(false);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const setFunderForm = (e) => {
    showSavingMsg();
    contributor.name_identifier_id = e.target.value;
    return axios.patch(
      '/stash_datacite/contributors/update',
      {authenticity_token, contributor},
      {
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
      },
    ).then((data) => {
      if (data.data.name_identifier_id === contributor.name_identifier_id && contributor.group_required) data.data.group_required = true;
      updateFunder(data.data);
      showSavedMsg();
      if (e.target.value === '') setSearch(false);
    });
  };

  const setFundingFromSearch = (fields) => {
    if (fields) {
      try {
        const contrib = JSON.parse(fields);
        contrib.identifier_type = 'ror';
        contrib.resource_id = resource.id;
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
          setSearch(false);
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
        contributor_name: contributor.name_identifier_id === NSF ? 'U.S. National Science Foundation' : 'National Institutes of Health',
        award_number: grantnum,
      }));
      setAutoBlurred(false);
    }
  }, [autoBlurred]);

  useEffect(() => {
    const rorCheck = [NIH, NSF, null, ''].includes(contributor.name_identifier_id) && !contributor.contributor_name;
    setSearch(rorCheck);
  }, []);

  return (
    search ? (
      <div className="funder-form">
        {contributor.name_identifier_id === NSF}
        <fieldset onChange={setFunderForm}>
          <legend>
            The granting organization is or is part of:
          </legend>
          <p className="radio_choice">
            <label>
              <input name="ror" type="radio" value={NIH} defaultChecked={contributor.name_identifier_id === NIH ? 'checked' : null} />
              U.S. National Institutes of Health
            </label>
            <label>
              <input name="ror" type="radio" value={NSF} defaultChecked={contributor.name_identifier_id === NSF ? 'checked' : null} />
              U.S. National Science Foundation
            </label>
            <label><input name="ror" type="radio" defaultChecked={null} value="" />Other</label>
          </p>
        </fieldset>
        {[NIH, NSF].includes(contributor.name_identifier_id) && (
          <div className="input-stack">
            <span>Search grants with your award number</span>
            <Autocomplete
              acText={grantnum}
              setAcText={setGrantnum}
              acID=""
              setAcID={setFundingFromSearch}
              setAutoBlurred={setAutoBlurred}
              supplyLookupList={supplyLookupList}
              nameFunc={nameFunc}
              idFunc={idFunc}
              controlOptions={
                {
                  labelText: 'Award number:',
                  htmlId: `award_lookup_${contributor.id}`,
                  isRequired: true,
                  desBy: `${contributor.id}award-ex`,
                }
              }
            />
            <div id={`${contributor.id}award-ex`}><i aria-hidden="true" />CA 123456-01A1</div>
          </div>
        )}
      </div>
    ) : (
      <FunderForm current={current} resourceId={resource.id} contributor={contributor} disabled={disabled} updateFunder={updateFunder} />
    )
  );
}

export default FundingSearch;
