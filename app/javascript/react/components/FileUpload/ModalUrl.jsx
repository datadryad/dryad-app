import React from 'react';
import ValidateFiles from './ValidateFiles';

const modal_url = React.forwardRef(({changedUrls, submitted, clickedClose}, ref) => (
  <dialog
    id="js-uploadmodal"
    className="c-uploadmodal"
    ref={ref}
    style={{
      position: 'fixed',
      width: '60%',
      height: '370px',
      maxWidth: '750px',
      minWidth: '220px',
    }}
  >
    <form method="dialog" onSubmit={submitted}>
      <div className="c-uploadmodal__header">
        <label htmlFor="location_urls" className="c-uploadmodal__textarea-url-label">
          Enter URLs
        </label>
        <button
          className="c-uploadmodal__button-close-modal"
          aria-label="close"
          type="button"
          onClick={clickedClose}
        />
      </div>
      <textarea
        id="location_urls"
        className="c-uploadmodal__textarea-url"
        name="url"
        onChange={changedUrls}
        placeholder="List file location URLs here"
      />
      <div className="c-uploadmodal__text-content">Place each URL on a new line.</div>
      <ValidateFiles
        id="confirm_to_validate"
        buttonLabel="Validate Files"
        checkConfirmed={false}
        disabled={false}
      />
    </form>
  </dialog>
));

export default modal_url;
