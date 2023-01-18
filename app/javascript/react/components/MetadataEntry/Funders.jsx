import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderForm from './FunderForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function Funders({
  resourceId, contributors, createPath, updatePath, deletePath, groupings,
}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const [funders, setFunders] = useState(contributors);
  const [disabled, setDisabled] = useState(contributors[0]?.name_identifier_id === '0');

  const addNewFunder = () => {
    console.log(`${(new Date()).toISOString()}: Adding funder`);
    const contributor = {
      contributor_name: '',
      contributor_type: 'funder',
      identifier_type: 'crossref_funder_id',
      name_identifier_id: '',
      resource_id: resourceId,
    };
    const contribJson = {authenticity_token, contributor};

    axios.post(createPath, contribJson, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't add new funder from remote server");
        }
        setFunders((prevState) => [...prevState, data.data]);
      });
  };

  if (funders.length < 1) addNewFunder();

  // delete a funder from the list
  const removeItem = (id) => {
    console.log(`${(new Date()).toISOString()}: deleting funder`);
    const trueDelPath = deletePath.replace('id_xox', id);
    showSavingMsg();

    // requiring the resource like this is weird in a controller for a model that isn't a resource, but it's how it is set up
    if (id && !`${id}`.startsWith('new')) {
      const submitVals = {
        authenticity_token,
        contributor: {
          id,
          resource_id: resourceId,
        },
      };
      axios.delete(trueDelPath, {
        data: submitVals,
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
      })
        .then((data) => {
          if (data.status !== 200) {
            console.log('Response failure not a 200 response from funders save');
          } else {
            console.log('deleted from funders');
          }
          showSavedMsg();
        });
    }
    setFunders((prevState) => prevState.filter((item) => (item.id !== id)));
  };

  // update the funder in the list from old to new values
  const updateFunder = (updatedContributor) => {
    // replace item in the funder list if it has changed
    setFunders((prevState) => prevState.map((funder) => (updatedContributor.id === funder.id ? updatedContributor : funder)));
  };

  const setNoFunders = async (e) => {
    const noFunders = e.currentTarget.checked;
    const [contributor] = contributors;
    setDisabled(noFunders);
    contributor.contributor_name = noFunders ? 'N/A' : '';
    contributor.name_identifier_id = noFunders ? '0' : '';
    // submit by json
    return axios.patch(
      updatePath,
      {authenticity_token, contributor},
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Accept: 'application/json',
        },
      },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from funders save');
      }
      // forces data update in the collection containing me
      updateFunder(contributor);
    });
  };

  return (
    <div style={{marginBottom: '20px'}}>
      {!disabled && (
        <>
          {funders.map((contrib) => (
            <FunderForm
              key={contrib.id}
              resourceId={resourceId}
              contributor={contrib}
              groupings={groupings}
              disabled={disabled}
              updatePath={updatePath}
              removeFunction={removeItem}
              updateFunder={updateFunder}
            />
          ))}
          <button
            className="t-describe__add-funder-button o-button__add"
            type="button"
            disabled={disabled}
            onClick={addNewFunder}
            style={{marginRight: '2em'}}
          >
          Add another funder
          </button>
        </>
      )}
      <label><input type="checkbox" checked={disabled} onChange={setNoFunders} /> No funding received</label>
    </div>
  );
}

export default Funders;

// resourceId, contributors, createPath, updatePath, deletePath

Funders.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  contributors: PropTypes.array.isRequired,
  createPath: PropTypes.string.isRequired,
  updatePath: PropTypes.string.isRequired,
  deletePath: PropTypes.string.isRequired,
};
