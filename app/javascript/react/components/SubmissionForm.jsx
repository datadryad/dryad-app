import React, {useState, useEffect} from 'react';

export default function SubmissionForm({
  steps, resource, previewRef, user,
}) {
  const [hasChanges, setChanges] = useState(!resource.previous_curated_resource);
  const [showR, setShowR] = useState(resource.display_readme);
  const [userComment, setUserComment] = useState(resource?.edit_histories?.[0]?.user_comment);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const {curator} = user;
  const {users} = resource;
  const submitter = users.find((u) => u.role === 'submitter');
  const isSubmitter = user.id === submitter.id;

  useEffect(() => {
    if (previewRef.current && resource.previous_curated_resource) {
      setChanges(!!previewRef.current.querySelector('ins, del, .ins, .del'));
    }
  }, [previewRef.current, resource]);
  return (
    <div id="submission-submit" role="status">
      {steps.some((s) => s.fail) && (
        <p>Edit sections and fix the errors above in order to complete your submission</p>
      )}
      {!steps.some((s) => s.fail) && !hasChanges && (
        <>
          <p>No changes have been made to the submission. Make changes to submit, or delete this version to revert to the one already submitted</p>
          <form action={`/resources/${resource.id}`} method="post">
            <input type="hidden" name="_method" value="delete" />
            <input type="hidden" name="authenticity_token" value={authenticity_token} />
            <button type="submit" className="o-button__plain-text0">Delete &amp; revert</button>
          </form>
        </>
      )}
      <form
        action="/stash_datacite/resources/submission"
        method="post"
        onSubmit={!hasChanges || steps.some((s) => s.fail) || (curator && !userComment)
          || (!isSubmitter && !curator) ? (e) => { e.preventDefault(); } : null}
      >
        {hasChanges && !steps.some((s) => s.fail) && (
          <>
            <input type="hidden" name="authenticity_token" value={authenticity_token} />
            <input type="hidden" name="resource_id" value={resource.id} />
            <input type="hidden" name="user_comment" value={userComment} />
            {!showR && <input type="hidden" name="hide_readme" value="true" />}
            {curator ? (
              <>
                <div role="heading" aria-level="2" className="input-label">Curation options:</div>
                <div className="radio_choice">
                  <label>
                    <input type="checkbox" onChange={(e) => setShowR(e.target.checked)} defaultChecked={!showR} />
                    Hide this README on the landing page
                  </label>
                </div>
                <label htmlFor="user_comment" className="screen-reader-only">Describe edits made</label>
                <textarea
                  rows={1}
                  id="user_comment"
                  value={userComment}
                  style={{flex: 1, minWidth: '200px', maxWidth: '800px'}}
                  onChange={(e) => setUserComment(e.target.value)}
                  placeholder="Describe edits made (required)"
                  required
                />
              </>
            ) : (
              <p>{isSubmitter ? 'Ready to complete your submission?' : 'Only the submitter may complete the submission.'}</p>
            )}
          </>
        )}
        <button
          type={!hasChanges || steps.some((s) => s.fail) || (curator && !userComment) || (!isSubmitter && !curator) ? 'button' : 'submit'}
          className="o-button__plain-text1"
          name="submit_button"
          aria-disabled={!hasChanges || steps.some((s) => s.fail) || (curator && !userComment) || (!isSubmitter && !curator) ? 'true' : null}
        >
          {curator ? 'Submit changes' : `Submit for ${resource.hold_for_peer_review ? 'peer review' : 'publication'}`}
        </button>
      </form>
    </div>
  );
}
