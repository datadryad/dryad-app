import React from 'react';

export default function ExitButton({resource}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  return (
    <form action={`/resources/${resource.id}/logout`} data-remote="false" method="post">
      <input type="hidden" name="authenticity_token" value={authenticity_token} />
      <button className="o-button__plain-text7" type="submit"><i className="fas fa-floppy-disk" aria-hidden="true" />Save & exit</button>
    </form>
  );
}

export function ExitIcon() {
  return <i className="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window) " role="img" />;
}
