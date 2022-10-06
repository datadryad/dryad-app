import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderForm from './FunderForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function Funders({
  resourceId, contributors, createPath, updatePath, deletePath,
}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const blankContrib = {
    contributor_name: '',
    contributor_type: 'funder',
    identifier_type: 'crossref_funder_id',
    name_identifier_id: '',
    resource_id: resourceId,
  };

  const [funders, setFunders] = useState(contributors);

  const addNewFunder = () => {
    console.log(`${(new Date()).toISOString()}: Adding funder`);
    const contribJson = {
      authenticity_token: csrf,
      contributor: blankContrib,
    };

    axios.post(createPath, contribJson, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't add new funder from remote server");
        }
        setFunders((prevState) => [...prevState, data.data]);
      });
  };

  if (funders.length < 1) {
    addNewFunder();
  }

  // delete a funder from the list
  const removeItem = (id) => {
    console.log(`${(new Date()).toISOString()}: deleting funder`);
    const trueDelPath = deletePath.replace('id_xox', id);
    showSavingMsg();

    // requiring the resource like this is weird in a controller for a model that isn't a resource, but it's how it is set up
    if (id && !`${id}`.startsWith('new')) {
      const submitVals = {
        authenticity_token: csrf,
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

  return (
    <>
      {funders.map((contrib) => (
        <FunderForm
          key={contrib.id}
          resourceId={resourceId}
          contributor={contrib}
          updatePath={updatePath}
          removeFunction={removeItem}
          updateFunder={updateFunder}
        />
      ))}
      <button
        className="t-describe__add-funder-button o-button__add"
        type="button"
        onClick={addNewFunder}
      >
        Add another funder
      </button>
    </>
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
