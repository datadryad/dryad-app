import React from 'react';

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
