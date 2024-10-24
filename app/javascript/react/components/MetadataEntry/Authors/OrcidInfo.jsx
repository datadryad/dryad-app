import React from 'react';
import PropTypes from 'prop-types';

export const orcidURL = (orcid) => (window.location.hostname === 'datadryad.org'
  ? `https://orcid.org/${orcid}`
  : `https://sandbox.orcid.org/${orcid}`);

export default function OrcidInfo({
  author, curator, ownerId,
}) {
  const orcidInfo = author.author_orcid ? orcidURL(author.author_orcid) : null;
  return (
    <>
      {orcidInfo && (
        <span>
          <i className="fab fa-orcid" aria-hidden="true" />&nbsp;
          <a href={orcidInfo} target="_blank" className="c-orcid__id" rel="noreferrer">{author.author_orcid}</a>
        </span>
      )}
      {ownerId === author.id && (
        <span>
          <i className="fas fa-address-card" aria-hidden="true" />&nbsp;Submitter
        </span>
      )}
      {(curator && !orcidInfo && author.orcid_invite_path) ? (
        <span>
          Associate &nbsp;<i className="fab fa-orcid" aria-hidden="true" />&nbsp;at {author.orcid_invite_path}
        </span>
      ) : ''}
    </>
  );
}

OrcidInfo.propTypes = {
  author: PropTypes.object.isRequired,
  curator: PropTypes.bool.isRequired,
  ownerId: PropTypes.number.isRequired,
};
