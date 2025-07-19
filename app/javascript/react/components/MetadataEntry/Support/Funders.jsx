import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg, showModalYNDialog} from '../../../../lib/utils';
import DragonDropList, {DragonListItem, orderedItems} from '../DragonDropList';
import FunderForm from './FunderForm';

function Funders({resource, setResource}) {
  const contributors = resource.contributors.filter((c) => c.contributor_type === 'funder');
  const [funders, setFunders] = useState(contributors);
  const [disabled, setDisabled] = useState(contributors[0]?.name_identifier_id === '0');

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const lastOrder = () => (funders.length ? Math.max(...funders.map((contrib) => contrib.funder_order)) + 1 : 0);

  const addNewFunder = () => {
    const contributor = {
      contributor_name: '',
      contributor_type: 'funder',
      identifier_type: 'ror',
      name_identifier_id: '',
      resource_id: resource.id,
      funder_order: lastOrder(),
    };
    const contribJson = {authenticity_token, contributor};

    axios.post(
      '/stash_datacite/contributors/create',
      contribJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("Couldn't add new funder");
        }
        setFunders((f) => [...f, data.data]);
      });
  };

  // delete a funder from the list
  const removeItem = (id) => {
    showSavingMsg();
    if (id && !`${id}`.startsWith('new')) {
      const submitVals = {
        authenticity_token,
        contributor: {id, resource_id: resource.id},
      };
      axios.delete(`/stash_datacite/contributors/${id}/delete`, {
        data: submitVals,
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
      })
        .then((data) => {
          if (data.status !== 200) {
            console.log('Response failure from funders delete');
          }
          showSavedMsg();
        });
    }
    setFunders((f) => f.filter((item) => (item.id !== id)));
  };

  // update the funder in the list from old to new values
  const updateFunder = (updated) => {
    setFunders((f) => f.map((funder) => (updated.id === funder.id ? updated : funder)));
  };

  const setNoFunders = async (e) => {
    const noFunders = e.currentTarget.checked;
    const [contributor] = funders;
    setDisabled(noFunders);
    contributor.contributor_name = noFunders ? 'N/A' : '';
    contributor.name_identifier_id = noFunders ? '0' : '';
    // submit by json
    const dels = funders.slice(1);
    dels.forEach((f) => removeItem(f.id));
    return axios.patch(
      '/stash_datacite/contributors/update',
      {authenticity_token, contributor},
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Accept: 'application/json',
        },
      },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure from funders save');
      }
      updateFunder(contributor);
    });
  };

  useEffect(() => {
    setResource((r) => ({...r, contributors: [...funders, ...r.contributors.filter((con) => con.contributor_type !== 'funder')]}));
    if (funders.length < 1) addNewFunder();
  }, [funders]);

  return (
    <div style={{marginBottom: '20px'}}>
      {!disabled && (
        <DragonDropList model="contributor" typeName="funder" items={funders} path="/stash_datacite/contributors/reorder" setItems={setFunders}>
          {orderedItems({items: funders, typeName: 'funder'}).map((contrib) => (
            <DragonListItem key={contrib.id} item={contrib} typeName="funder">
              <FunderForm resourceId={resource.id} contributor={contrib} disabled={disabled} updateFunder={updateFunder} />
              <button
                type="button"
                className="remove-record"
                onClick={() => {
                  showModalYNDialog('Are you sure you want to remove this funder?', () => {
                    removeItem(contrib.id);
                  });
                }}
                aria-label="Remove funding"
                title="Remove"
              >
                <i className="fas fa-trash-can" aria-hidden="true" />
              </button>
            </DragonListItem>
          ))}
        </DragonDropList>
      )}
      <div className="funder-buttons">
        {!disabled && <div />}
        <label><input type="checkbox" checked={disabled} onChange={setNoFunders} /> No funding received</label>
        <button
          className="o-button__plain-text1"
          type="button"
          disabled={disabled}
          onClick={addNewFunder}
        >
          + Add funder
        </button>
      </div>
    </div>
  );
}

export default Funders;

Funders.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
