import React from 'react';
import PropTypes from 'prop-types';

export const urlCheck = (url) => {
  if (!url) return true;
  return URL.canParse(url);
};

export const verifiedCheck = (id) => {
  if (!id.related_identifier) return true;
  return id.verified;
};

function RelatedWorksErrors(
  {relatedIdentifier},
) {
  if (relatedIdentifier.related_identifier) {
    if (!urlCheck(relatedIdentifier.related_identifier)) {
      return (
        <div className="callout err">
          <p>The URL is not valid. Make sure your URL is correct and begins with <code>http://</code> or <code>https://</code>.</p>
        </div>
      );
    }
    if (!relatedIdentifier.verified) {
      return (
        <div className="callout warn">
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
