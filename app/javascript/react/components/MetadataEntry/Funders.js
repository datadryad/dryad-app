import React, {useState} from 'react';
import {nanoid} from 'nanoid';
import axios from 'axios';
import PropTypes from 'prop-types';
import FunderForm from './FunderForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function Funders({
  resourceId, contributors, createPath, updatePath, deletePath,
}) {
  const blankFunder = () => ({
    id: `new${nanoid()}`, contributor_name: '', contributor_type: 'funder', identifier_type: '', name_identifier_id: '',
  });

  const [funders, setFunders] = useState(contributors);

  if (funders.length < 1) {
    setFunders([blankFunder()]);
  }

  const removeItem = (id) => {
    const trueDelPath = deletePath.replace('id_xox', id);
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
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
    setFunders(funders.filter((item) => (item.id !== id)));
  };

  const updateFunder = (id, newContributor) => {
    // replace item in the funder list if it has changed
    setFunders(funders.map((funder) => (id === funder.id ? newContributor : funder)));
  };

  return (
    <>
      {funders.map((contrib) => (
        <FunderForm
          key={contrib.id}
          resourceId={resourceId}
          contributor={contrib}
          createPath={createPath}
          updatePath={updatePath}
          removeFunction={removeItem}
          updateFunder={updateFunder}
        />
      ))}
      {/* eslint-disable jsx-a11y/anchor-is-valid */}
      <a
        href="#"
        className="t-describe__add-funder-button o-button__add"
        role="button"
        onClick={(e) => {
          e.preventDefault();
          setFunders((prev) => [...prev, blankFunder()]);
        }}
      >
        add another funder
      </a>
      {/* eslint-enable jsx-a11y/anchor-is-valid */}
    </>
  );
}

export default Funders;

// resourceId, contributors, createPath, updatePath, deletePath

Funders.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string,PropTypes.number]).isRequired,
  contributors: PropTypes.array.isRequired,
  createPath: PropTypes.string.isRequired,
  updatePath: PropTypes.string.isRequired,
  deletePath: PropTypes.string.isRequired,
};
