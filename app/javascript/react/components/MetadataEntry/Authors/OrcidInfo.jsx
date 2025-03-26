import React from 'react';
import PropTypes from 'prop-types';

export const orcidURL = (orcid) => (window.location.hostname === 'datadryad.org'
  ? `https://orcid.org/${orcid}`
  : `https://sandbox.orcid.org/${orcid}`);

export default function OrcidInfo({author, curator}) {
  const orcidInfo = author.author_orcid ? orcidURL(author.author_orcid) : null;

  const copyPath = (e) => {
    const copyButton = e.currentTarget.firstElementChild;
    const {path} = e.currentTarget.previousSibling.dataset;
    navigator.clipboard.writeText(path).then(() => {
      // Successful copy
      copyButton.parentElement.setAttribute('title', 'Invite URL copied');
      copyButton.classList.remove('fa-paste');
      copyButton.classList.add('fa-check');
      copyButton.innerHTML = '<span class="screen-reader-only">Invite URL copied</span>';
      setTimeout(() => {
        copyButton.parentElement.setAttribute('title', 'Copy ORCID invite URL');
        copyButton.classList.add('fa-paste');
        copyButton.classList.remove('fa-check');
        copyButton.innerHTML = '';
      }, 2000);
    });
  };

  return (
    <>
      {orcidInfo && (
        <div className="author-one-line" style={{marginRight: 'auto'}}>
          <i className="fab fa-orcid" aria-hidden="true" />&nbsp;
          <a
            href={orcidInfo}
            aria-label={`ORCID profile for ${[author.author_first_name, author.author_last_name].filter(Boolean).join(' ')}`}
            target="_blank"
            className="c-orcid__id"
            rel="noreferrer"
          >{author.author_orcid}
          </a>
        </div>
      )}
      {(curator && !orcidInfo && author.orcid_invite_path) && (
        <div className="author-one-line">
          <span data-path={author.orcid_invite_path} title={author.orcid_invite_path}>
            Associate&nbsp;<i className="fab fa-orcid" aria-label="ORCID" role="img" />
          </span>
          <span
            className="copy-icon"
            role="button"
            tabIndex="0"
            aria-label="Copy ORCID invite URL"
            title="Copy ORCID invite URL"
            onClick={copyPath}
            onKeyDown={(e) => {
              if (e.key === ' ' || e.key === 'Enter') {
                copyPath(e);
              }
            }}
          ><i className="fa fa-paste" role="status" />
          </span>
        </div>
      )}
    </>
  );
}

OrcidInfo.propTypes = {
  author: PropTypes.object.isRequired,
  curator: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.bool,
  ]).isRequired,
};
