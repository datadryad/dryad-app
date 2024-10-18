import React from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';
import {urlCheck} from './RelatedWorksErrors';

export {default} from './RelatedWorks';
export {default as WorksPreview} from './WorksPreview';

export const worksCheck = (resource, review) => {
  if (resource.resource_type.resource_type === 'collection') {
    const collection = resource.related_identifiers.filter((ri) => ri.relation_type === 'haspart');
    if (resource.related_identifiers.some((ri) => !!ri.related_identifier && ri.work_type !== 'primary_article')
      || resource.accepted_agreement || review) {
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
    }
  } else {
    const urlError = resource.related_identifiers.findIndex((ri) => !urlCheck(ri.related_identifier));
    if (urlError >= 0) {
      return (
        <p className="error-text" id="works_error" data-index={urlError}>
          {upCase(ordinalNumber(urlError + 1))} related work is not a valid DOI or URL
        </p>
      );
    }
  }
  return false;
};
