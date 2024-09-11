import React from 'react';
import PropTypes from 'prop-types';

export default function OrcidInfo({
  dryadAuthor, curator, correspondingAuthorId,
}) {
  let orcidInfo = null;
  if (dryadAuthor.author_orcid) {
    orcidInfo = (window.location.hostname === 'datadryad.org'
      ? `https://orcid.org/${dryadAuthor.author_orcid}`
      : `https://sandbox.orcid.org/${dryadAuthor.author_orcid}`);
  }

  return (
    <div className="c-orcid">
      {orcidInfo && (
        <div className="c-orcid__div" style={{marginRight: '2em'}}>
          <i className="fab fa-orcid" aria-hidden="true" />
          <a href={orcidInfo} target="_blank" className="c-orcid__id" rel="noreferrer">{orcidInfo}</a>
        </div>
      )}
      {correspondingAuthorId === dryadAuthor.id && (
        <div className="c-orcid__div" style={{marginLeft: '2em'}}><i className="fa fa-address-card-o" aria-hidden="true" />
          &nbsp;&nbsp;Corresponding author
        </div>
      )}
      {(curator && !orcidInfo && dryadAuthor.orcid_invite_path) ? (
        <div className="c-orcid__div">
          Associate &nbsp;<i className="fab fa-orcid" aria-hidden="true" />&nbsp;at {dryadAuthor.orcid_invite_path}
        </div>
      ) : ''}
    </div>
  );
}

OrcidInfo.propTypes = {
  dryadAuthor: PropTypes.object.isRequired,
  curator: PropTypes.bool.isRequired,
  correspondingAuthorId: PropTypes.number.isRequired,
};
