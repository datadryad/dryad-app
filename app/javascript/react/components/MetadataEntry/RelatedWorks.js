import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import RelatedWorkForm from './RelatedWorkForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function RelatedWorks(
    {resourceId,
      relatedIdentifiers,
      workTypes}
) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const blankRelated = {
    related_identifier: '',
    related_identifier_type: 'doi',
    relation_type: 'iscitedby',
    resource_id: resourceId,
    work_type: 'supplemental_information'
  };

  const [works, setWorks] = useState(relatedIdentifiers);

  const addNewWork = () => {
    console.log(`${(new Date()).toISOString()}: Adding Related Works`);
    const contribJson = {
      authenticity_token: csrf,
      realedWork: blankRelated,
    };

    axios.post('ldkeh', contribJson, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
        .then((data) => {
          if (data.status !== 200) {
            console.log("couldn't add new relatedWork from remote server");
          }
          setWorks((prevState) => [...prevState, data.data]);
        });
  };

  if (works.length < 1) {
    addNewWork();
  }

  const removeItem = (id) => {
    console.log(`${(new Date()).toISOString()}: deleting relatedWork`);
    const trueDelPath = 'some_url'
    showSavingMsg();

    // requiring the resource like this is weird in a controller for a model that isn't a resource, but it's how it is set up
    if (id && !`${id}`.startsWith('new')) {
      const submitVals = {
        authenticity_token: csrf,
        contributor: {
          id,
          resource_id: 'resourceId',
        },
      };
      axios.delete(trueDelPath, {
        data: submitVals,
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
      })
          .then((data) => {
            if (data.status !== 200) {
              console.log('Response failure not a 200 response related works deletion');
            } else {
              console.log('deleted from related works');
            }
            showSavedMsg();
          });
    }
    // setFunders((prevState) => prevState.filter((item) => (item.id !== id)));
  };


  // update the work in the list from old to new values
  const updateWork = (updatedRelatedId) => {
    // replace item in the funder list if it has changed
    setWorks((prevState) => prevState.map((tempRel) => (updatedRelatedId.id === tempRel.id ? updatedRelatedId : tempRel)));
  };

  return (
      <fieldset className="c-fieldset">
        <legend className="c-fieldset__legend">
          <span className="c-input__hint">
            Are there any preprints, articles, datasets, software packages, or supplemental
            information that have resulted from or are related to this Data Publication?
          </span>
        </legend>
        <div className="replaceme-related-works">
          {works.map((relatedIdentifier) => (
              <RelatedWorkForm
                  key={relatedIdentifier.id}
                  relatedIdentifier={relatedIdentifier}
                  workTypes={workTypes}
                  removeFunction={removeItem}
                  updateWork={updateWork}
              />
          ))}
        </div>
        <a
            href="#"
            className="o-button__add"
            role="button"
            onClick={(e) => {
              e.preventDefault();
              addNewWork();
            }}
        >
          add another related work
        </a>
      </fieldset>
  );
}

export default RelatedWorks;