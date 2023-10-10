import React from 'react';
import ValidateFiles from './ValidateFiles';

const modal_url = React.forwardRef(({changedUrls, submitted, clickedClose}, ref) => (
  <dialog
    id="js-uploadmodal"
    className="modalDialog"
    ref={ref}
  >
    <form method="dialog" onSubmit={submitted}>
      <h1 className="c-uploadmodal__header">
        <label htmlFor="location_urls">
          Enter URLs
        </label>
        <button
          className="button-close-modal"
          aria-label="close"
          type="button"
          onClick={clickedClose}
        />
      </h1>
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
        buttonLabel="Validate files"
        checkConfirmed={false}
        disabled={false}
      />
    </form>
  </dialog>
));

export default modal_url;
