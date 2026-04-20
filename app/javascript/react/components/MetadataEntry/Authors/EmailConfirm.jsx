import React from 'react';
import {createPortal} from 'react-dom';
import {orcidURL} from './OrcidInfo';

export default function EmailConfirm({
  email, author, reset, confirm,
}) {
  return (
    <>
      {createPortal(
        <dialog
          id={`confirm-dialog${author.id}`}
          className="modalDialog"
          role="alertdialog"
          aria-labelledby={`confirm-${author.id}-title`}
          aria-describedby={`confirm-${author.id}-desc`}
          aria-modal="true"
        >
          <form style={{maxWidth: '600px'}}>
            <h1 id={`confirm-${author.id}-title`}>
            Connect this person with this email?
            </h1>
            <div>
              <p id={`confirm-${author.id}-desc`}>
              This will associate the email address <b>{email}</b> with the ORCID{' '}
                <span className="author-one-line" style={{marginRight: 'auto'}}>
                  <i className="fab fa-orcid" aria-hidden="true" />&nbsp;
                  <a
                    href={orcidURL(author.author_orcid)}
                    aria-label={`ORCID profile for ${[author.author_first_name, author.author_last_name].filter(Boolean).join(' ')}`}
                    target="_blank"
                    className="c-orcid__id"
                    rel="noreferrer"
                  >{author.author_orcid}
                  </a>
                </span> throughout Dryad. Complete this action?
              </p>
            </div>
            <div className="c-modal__buttons-right">
              <button
                type="submit"
                className="o-button__plain-text2"
                onClick={() => {
                  confirm();
                  document.getElementById(`confirm-dialog${author.id}`).close();
                }}
              >Add email
              </button>
              <button
                type="button"
                className="o-button__plain-text7"
                onClick={() => {
                  reset();
                  document.getElementById(`confirm-dialog${author.id}`).close();
                }}
              >
              Cancel
              </button>
            </div>
          </form>
        </dialog>,
        document.body,
      )}
    </>
  );
}
