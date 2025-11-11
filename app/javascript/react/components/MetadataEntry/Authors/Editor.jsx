import React from 'react';
import {createPortal} from 'react-dom';
import {upCase} from '../../../../lib/utils';

export default function Editor({
  user, author, editor, users, invite,
}) {
  const creator = users.find((u) => u.role === 'creator');
  const submitter = users.find((u) => u.role === 'submitter');
  const isCreator = user.id === creator.id;
  const isSubmitter = user.id === submitter.id;
  const permission = user.curator || isCreator || isSubmitter;
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
          {createPortal(
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
              <form style={{maxWidth: '600px'}}>
                <h1 id={`invite-${author.id}-title`}>
                  Invite {author.author_first_name ? [author.author_first_name, author.author_last_name].join(' ') : author.author_email}
                </h1>
                <div id={`invite-${author.id}-alert`} role="alert" className="callout alt" />
                <div>
                  <p id={`invite-${author.id}-desc`}>
                    You may invite this author as a collaborator on the submission.
                  </p>
                  {isCreator || user.curator ? (
                    <>
                      <p>
                        One collaborator must also be the submitter.
                        The submitter is responsible for approving the submission for curation and publication,{' '}
                        and will be the point of contact with Dryad for any revisions during curation.
                      </p>
                      <p>
                        {author.author_email} should be invited to{' '}
                        <select id={`role-selector${author.id}`} name="role" className="c-input__select" required>
                          <option value="" aria-label="Select a role" />
                          <option value="collaborator">Collaborate</option>
                          <option value="submitter">Collaborate and submit</option>
                        </select>
                      </p>
                      <p>Choosing &quot;Collaborate and submit&quot; will replace the current submitter.</p>
                    </>
                  ) : (
                    <>
                      <input type="hidden" name="role" id={`role-selector${author.id}`} value="collaborator" />
                      <p>
                        Collaborators are able to edit all elements of a submission, but are unable to submit for publication or peer review.
                        You must complete the submission, and you will be the point of contact with Dryad for any revisions during curation.
                      </p>
                    </>
                  )}
                </div>
                <div className="c-modal__buttons-right">
                  <button
                    type="submit"
                    className="o-button__plain-text2"
                    onClick={(e) => {
                      invite(e, author, document.getElementById(`role-selector${author.id}`).value);
                    }}
                  >Invite
                  </button>
                  <button
                    type="button"
                    className="o-button__plain-text7"
                    onClick={() => document.getElementById(`invite-dialog${author.id}`).close()}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </dialog>,
            document.body,
          )}
        </>
      )}
    </>
  );
}
