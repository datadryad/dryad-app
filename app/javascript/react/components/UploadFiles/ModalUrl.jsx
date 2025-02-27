import React from 'react';

const modal_url = React.forwardRef(({changedUrls, submitted, clickedClose}, ref) => (
  <dialog
    id="js-uploadmodal"
    className="modalDialog"
    aria-modal="true"
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
      <input
        type="submit"
        id="validate_files"
        className="c-uploadmodal__button-validate o-button__submit"
        value="Validate files"
      />
    </form>
  </dialog>
));

export default modal_url;
