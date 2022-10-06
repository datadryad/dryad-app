import React from 'react';
import PropTypes from 'prop-types';

export default function OrcidInfo({
  dryadAuthor, curator, correspondingAuthorId,
}) {
  let orcidInfo = null;
  if (dryadAuthor.author_orcid) {
    orcidInfo = (window.location.hostname.includes('datadryad.org')
      ? `https://orcid.org/${dryadAuthor.author_orcid}`
      : `https://sandbox.orcid.org/${dryadAuthor.author_orcid}`);
  }

  return (
    <div className="c-orcid">
      {orcidInfo && (
        <div className="c-orcid__div" style={{marginRight: '2em'}}>
          <span className="c-orcid__icon" />
          <a href={orcidInfo} target="_blank" className="c-orcid__id" rel="noreferrer">{orcidInfo}</a>
        </div>
      )}
      {correspondingAuthorId === dryadAuthor.id && (
        <div className="c-orcid__div" style={{marginLeft: '2em'}}><i className="fa fa-address-card-o" aria-hidden="true" />
          &nbsp;&nbsp;Corresponding Author
        </div>
      )}
      {(curator && !orcidInfo && dryadAuthor.orcid_invite_path) ? (
        <div className="c-orcid__div">
          Associate &nbsp;<span className="c-orcid__icon" />&nbsp;at {dryadAuthor.orcid_invite_path}
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
