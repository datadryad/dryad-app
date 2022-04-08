import React from 'react';
import PropTypes from 'prop-types';

export default function OrcidInfo({dryadAuthor, curator}) {
  let orcidInfo = null;
  if (dryadAuthor.author_orcid) {
    /* eslint-disable no-restricted-globals */
    orcidInfo = (location.hostname.includes('datadryad.org')
      ? `https://orcid.org/${dryadAuthor.author_orcid}`
      : `https://sandbox.orcid.org/${dryadAuthor.author_orcid}`);
    /* eslint-enable no-restricted-globals */
  }

  return (
    <>
      {orcidInfo
          && (
          <div className="c-orcid">
            <span className="c-orcid__icon" /><a href={orcidInfo} target="_blank" className='c-orcid__id' rel="noreferrer">{orcidInfo}</a>
          </div>
          )}
      {(curator && dryadAuthor.orcid_invite_path
        ? (
          <div className="c-orcid">
            Associate &nbsp;<span className="c-orcid__icon" />&nbsp;at {dryadAuthor.orcid_invite_path}
          </div>
        ) : '')}
    </>
  );
}

OrcidInfo.propTypes = {
  dryadAuthor: PropTypes.object.isRequired,
  curator: PropTypes.bool.isRequired,
};
