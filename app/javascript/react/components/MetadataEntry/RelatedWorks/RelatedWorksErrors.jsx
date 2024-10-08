import React from 'react';
import PropTypes from 'prop-types';

export const urlCheck = (url) => {
  if (!url) return true;
  return URL.canParse(url);
};

function RelatedWorksErrors(
  {relatedIdentifier},
) {
  if (relatedIdentifier.related_identifier) {
    if (!urlCheck(relatedIdentifier.related_identifier)) {
      return (
        <div className="callout warn" role="alert">
          <p>The URL is not valid. Make sure your URL is correct and complete.</p>
        </div>
      );
    }
    if (!relatedIdentifier.verified) {
      return (
        <div className="callout warn" role="alert">
          <p>The web page cannot be verified. Make sure your URL is correct.</p>
        </div>
      );
    }
  }
  return null;
}

export default RelatedWorksErrors;

RelatedWorksErrors.propTypes = {
  relatedIdentifier: PropTypes.object.isRequired,
};
