import React from 'react';

export default function ExitButton({resource}) {
  const editors = [...new Set(resource.users.map((u) => u.id))];
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const previous = resource.previous_curated_resource;
  return (
    <>
      <form
        action={`/dashboard/contact_helpdesk/${resource.identifier.id}`}
        data-remote="true"
        method="get"
      >
        <input type="hidden" name="authenticity_token" value={authenticity_token} />
        <button className="o-button__plain-text7" type="submit"><i className="fas fa-circle-question" aria-hidden="true" />Get help</button>
      </form>
      <form
        action={`/resources/${resource.id}/logout`}
        data-confirm={
          (previous && 'Are you sure you want to exit without submitting your changes?')
          || (editors.length === 1 && 'Are you sure you want to exit without submitting your data?')
          || null
        }
        data-remote="false"
        method="post"
      >
        <input type="hidden" name="authenticity_token" value={authenticity_token} />
        <button className="o-button__plain-text7" type="submit"><i className="fas fa-floppy-disk" aria-hidden="true" />Save & exit</button>
      </form>
    </>
  );
}

export function ExitIcon() {
  return <i className="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window) " role="img" />;
}
