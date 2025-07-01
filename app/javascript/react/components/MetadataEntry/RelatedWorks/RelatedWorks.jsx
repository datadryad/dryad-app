import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import RelatedWorkForm from './RelatedWorkForm';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function RelatedWorks({resource, setResource, current}) {
  const resourceType = resource.resource_type.resource_type;
  const related_works = resource.related_identifiers.filter((ri) => ri.work_type !== 'primary_article');
  const [works, setWorks] = useState(related_works);
  const [workTypes, setWorkTypes] = useState([]);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const addNewWork = () => {
    const stash_datacite_related_identifier = {
      related_identifier: '',
      related_identifier_type: 'doi',
      relation_type: resourceType === 'collection' ? 'haspart' : 'iscitedby',
      resource_id: resource.id,
      work_type: resourceType === 'collection' ? 'dataset' : 'article',
    };
    const workJson = {authenticity_token, stash_datacite_related_identifier};

    axios.post(
      '/stash_datacite/related_identifiers/create',
      workJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        setWorks((w) => [...w, data.data]);
      })
      .catch(() => {
        console.log("Couldn't add new related work");
      });
  };

  const removeItem = (id) => {
    showSavingMsg();
    const submitVals = {
      authenticity_token,
    };
    axios.delete(`/stash_datacite/related_identifiers/${id}/delete`, {
      data: submitVals,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    })
      .then((data) => {
        if (data.status !== 200) {
          console.log('Response failure from related works deletion');
        }
        showSavedMsg();
      });
    setWorks((w) => w.filter((item) => (item.id !== id)));
  };

  // update the work in the list from old to new values
  const updateWork = (updatedRelatedId) => {
    setWorks((w) => w.map((tempRel) => (updatedRelatedId.id === tempRel.id ? updatedRelatedId : tempRel)));
  };

  useEffect(() => {
    setResource((r) => ({...r, related_identifiers: [...works, ...r.related_identifiers.filter((ri) => ri.work_type === 'primary_article')]}));
    if (works.length < 1) addNewWork();
  }, [works]);

  useEffect(() => {
    async function getTypes() {
      axios.get('/stash_datacite/related_identifiers/types').then((data) => {
        const worktypes = data.data;
        if (resourceType === 'collection') {
          const [zero, one] = worktypes;
          worktypes[0] = one;
          worktypes[1] = zero;
        }
        setWorkTypes(worktypes);
      });
    }
    if (current && !workTypes.length) getTypes();
  }, [current]);

  return (
    <>
      {resource.related_identifiers.find((w) => w.work_type === 'primary_article') && (
        <div className="callout alt">
          <p>
            <span className="input-label" style={{marginRight: '2ch'}}>Primary article:</span>
            <span style={{fontSize: '1rem'}}>
              <i className="fas fa-newspaper" aria-hidden="true" style={{marginRight: '.5ch'}} />
              {resource.related_identifiers.find((w) => w.work_type === 'primary_article').related_identifier}
              {resource.resource_publication.publication_name && (
                <> from <b>{resource.resource_publication.publication_name}</b></>
              )}
            </span>
          </p>
        </div>
      )}
      <p>
        {resourceType === 'collection'
          ? `Please list all the datasets in the collection, as well as any identifiable related or resulting articles, 
            preprints, software packages, or supplemental information.`
          : `Are there any preprints, articles, datasets, software packages, or supplemental information that have 
            resulted from or are related to this submission?`}
      </p>
      <div className="related-works">
        {works.map((work) => (
          <RelatedWorkForm
            key={work.id}
            relatedIdentifier={work}
            workTypes={workTypes}
            removeFunction={removeItem}
            updateWork={updateWork}
          />
        ))}
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
