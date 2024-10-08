import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import RelatedWorkForm from './RelatedWorkForm';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function RelatedWorks({resource, setResource}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const resourceType = resource.resource_type.resource_type;
  const [workTypes, setWorkTypes] = useState([]);
  const [works, setWorks] = useState(resource.related_identifiers);

  const blankRelated = {
    related_identifier: '',
    related_identifier_type: 'doi',
    relation_type: resourceType === 'collection' ? 'haspart' : 'iscitedby',
    resource_id: resource.id,
    work_type: resourceType === 'collection' ? 'dataset' : 'article',
  };

  const addNewWork = () => {
    const contribJson = {
      authenticity_token,
      stash_datacite_related_identifier: blankRelated,
    };

    axios.post(
      '/stash_datacite/related_identifiers/create',
      contribJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't add new relatedWork to the remote server");
        }
        setWorks((w) => [...w, data.data]);
      });
  };

  if (works.length < 1) {
    addNewWork();
  }

  const removeItem = (id) => {
    const trueDelPath = `/stash_datacite/related_identifiers/${id}/delete`;
    showSavingMsg();

    const submitVals = {
      authenticity_token,
    };
    axios.delete(trueDelPath, {
      data: submitVals,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    })
      .then((data) => {
        if (data.status !== 200) {
          console.log('Response failure not a 200 response from related works deletion');
        }
        showSavedMsg();
      });
    setWorks((w) => w.filter((item) => (item.id !== id)));
  };

  // update the work in the list from old to new values
  const updateWork = (updatedRelatedId) => {
    // replace item in the funder list if it has changed
    setWorks((w) => w.map((tempRel) => (updatedRelatedId.id === tempRel.id ? updatedRelatedId : tempRel)));
  };

  useEffect(() => {
    setResource((r) => ({...r, related_identifiers: works}));
  }, [works]);

  useEffect(() => {
    async function getTypes() {
      axios.get('/stash_datacite/related_identifiers/types').then((data) => {
        const worktypes = data.data;
        if (resourceType === 'collection') {
          const [zero, one] = workTypes;
          workTypes[0] = one;
          worktypes[1] = zero;
        }
        setWorkTypes(worktypes);
      });
    }
    getTypes();
  }, []);

  return (
    <>
      <h2>Related works</h2>
      <p>
        {resourceType === 'collection'
          ? `Please list all the datasets in the collection, as well as any identifiable related or resulting articles, 
            preprints, software packages, or supplemental information.`
          : `Are there any preprints, articles, datasets, software packages, or supplemental information that have 
            resulted from or are related to this Data Publication?`}
      </p>
      <div className="related-works">
        {works.map((relatedIdentifier) => {
          if (relatedIdentifier.work_type === 'primary_article') return null;
          return (
            <RelatedWorkForm
              key={relatedIdentifier.id}
              relatedIdentifier={relatedIdentifier}
              workTypes={workTypes}
              removeFunction={removeItem}
              updateWork={updateWork}
            />
          );
        })}
      </div>
      <div style={{textAlign: 'right'}}>
        <button
          className="o-button__plain-text1"
          type="button"
          onClick={addNewWork}
        >
          + Add work
        </button>
      </div>
    </>
  );
}

export default RelatedWorks;

RelatedWorks.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
