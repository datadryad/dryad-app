import React from 'react';
import {upCase} from '../../../../lib/utils';

export default function Editor({
  author, editor, permission, invite,
}) {
  return (
    <>
      {editor && editor.role && (
        <div className="author-one-line" style={{marginLeft: 'auto'}}>
          <i className={`fas fa-user-${['creator', 'submitter'].includes(editor.role) ? 'tag' : 'pen'}`} aria-hidden="true" />&nbsp;
          {upCase(editor.role)}
        </div>
      )}
      {!editor && permission && (
        <>
          <div className="author-one-line" style={{marginLeft: 'auto'}}>
            {author.edit_code?.edit_code ? (
              <span><i className="fa-solid fa-envelope-circle-check" style={{marginRight: '.5ch'}} />Invited {author.edit_code.role}</span>
            ) : (
              <button
                type="button"
                className="o-button__plain-textlink"
                disabled={!author.author_email}
                aria-controls={`invite-dialog${author.id}`}
                onClick={() => document.getElementById(`invite-dialog${author.id}`).showModal()}
                title={!author.author_email ? 'Author email is required' : null}
              >
                <i className="fas fa-envelope-open-text" aria-hidden="true" style={{marginRight: '.5ch'}} />Invite to edit
              </button>
            )}
          </div>
          <dialog
            id={`invite-dialog${author.id}`}
            className="modalDialog"
            role="alertdialog"
            aria-labelledby={`invite-${author.id}-title`}
            aria-describedby={`invite-${author.id}-desc`}
            aria-modal="true"
          >
            <div className="modalClose">
              <button aria-label="Close" type="button" onClick={() => document.getElementById(`invite-dialog${author.id}`).close()} />
            </div>
            <div style={{maxWidth: '600px'}}>
              <h1 id={`invite-${author.id}-title`}>
                Invite {author.author_first_name ? [author.author_first_name, author.author_last_name].join(' ') : author.author_email}
              </h1>
              <div id={`invite-${author.id}-alert`} role="alert" className="callout alt" />
              <div>
                <p id={`invite-${author.id}-desc`}>
                  You may invite this author as a collaborator on the submission.
                </p>
                <p>
                  One collaborator must also be the submitter.
                  The submitter is responsible for approving the submission for curation and publication,{' '}
                  and will be the point of contact with Dryad for any revisions during curation.
                </p>
                <p>
                  {author.author_email} should be invited to{' '}
                  <select name="role" className="c-input__select" required>
                    <option value aria-label="Select a role" />
                    <option value="collaborator">Collaborate</option>
                    <option value="submitter">Collaborate and submit</option>
                  </select>
                </p>
                <p>Choosing &quot;Collaborate and submit&quot; will replace the current submitter.</p>
              </div>
              <div className="c-modal__buttons-right">
                <button
                  type="button"
                  className="o-button__plain-text2"
                  onClick={(e) => {
                    invite(author, document.querySelector(`#invite-dialog${author.id} select`).value);
                    e.target.disabled = true;
                    e.target.hidden = true;
                    e.target.parentElement.previousElementSibling.hidden = true;
                    e.target.nextElementSibling.innerHTML = 'Close';
                  }}
                >Invite
                </button>
                <button type="button" className="o-button__plain-text7" onClick={() => document.getElementById(`invite-dialog${author.id}`).close()}>
                  Cancel
                </button>
              </div>
            </div>
          </dialog>
        </>
      )}
    </>
  );
}
