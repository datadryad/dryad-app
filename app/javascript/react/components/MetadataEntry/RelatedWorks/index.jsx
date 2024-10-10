import React, {Fragment} from 'react';
import {sentenceCase} from 'change-case';

export {default} from './RelatedWorks';

export const worksCheck = (resource) => {
  if (resource.resource_type.resource_type !== 'collection') return false;
  const collection = resource.related_identifiers.filter((ri) => ri.relation_type === 'haspart');
  if (collection.length === 0) {
    return (
      <p className="error-text" id="works_error">The related works in the collection are required</p>
    );
  }
  if (collection.length < 2) {
    return (
      <p className="error-text" id="works_error">More than one dataset must be included in a collection</p>
    );
  }
  return false;
};

const nameit = (name, arr) => {
  const plural = !['software', 'supplemental_information'].includes(name) && arr.length > 1 ? 's' : '';
  return `${sentenceCase(name)}${plural}`;
};

export function WorksPreview({resource, admin}) {
  const ris = resource.related_identifiers.filter((ri) => ri.work_type !== 'primary_article' && !!ri.related_identifier);
  const works = Object.groupBy(ris, ({work_type}) => work_type);
  const icons = {
    article: 'far fa-newspaper',
    dataset: 'fas fa-table',
    software: 'fas fa-code-branch',
    preprint: 'fas fa-receipt',
    supplemental_information: 'far fa-file-lines',
    data_management_plan: 'fas fa-list-check',
  };
  if (ris.length > 0) {
    return (
      <>
        <h3 className="o-heading__level2" style={{marginBottom: '-1rem'}}>Related works</h3>
        {Object.keys(works).map((type) => (
          <Fragment key={type}>
            <h4 className="o-heading__level3">{nameit(type, works[type])}</h4>
            <ul className="o-list">
              {works[type].map((w) => (
                <li key={w.id}>
                  <a href={w.related_identifier} target="_blank" rel="noreferrer">
                    <i className={icons[type]} aria-hidden="true" style={{marginRight: '.5ch'}} />{w.related_identifier}
                    <span className="screen-reader-only"> (opens in new window)</span>
                  </a>
                  {admin && !w.verified && (
                    <i className="fas fa-link-slash unmatched-icon" role="note" aria-label="Unverified link" title="Unverified link" />
                  )}
                </li>
              ))}
            </ul>
          </Fragment>
        ))}
      </>
    );
  }
  return null;
}
