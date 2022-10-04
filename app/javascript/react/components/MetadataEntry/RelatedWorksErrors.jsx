import React from 'react';
import PropTypes from 'prop-types';

function RelatedWorksErrors(
  {relatedIdentifier},
) {
  // empty related identifier
  if (!relatedIdentifier.related_identifier) {
    return (null);
  }

  return (
    <div>
      {!relatedIdentifier.valid_url_format
        && (
          <div className="o-metadata__autopopulate-message">
            We can&apos;t match the identifier provided with any known repository or publisher. Please make sure you have
            included the correct URL or DOI.
          </div>
        )}

      {!relatedIdentifier.verified
        && (
          <div className="o-metadata__autopopulate-message">
            The identifier provided could not be verified. Please make sure you have included the correct DOI
            for your related work.
          </div>
        )}
    </div>
  );
}

export default RelatedWorksErrors;

RelatedWorksErrors.propTypes = {
  relatedIdentifier: PropTypes.object.isRequired,
};
