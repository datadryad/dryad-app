/* eslint-disable react/prop-types */
// TODO: look into how important this is to set these.  Not mentioned in what I'd looked at so far and not sure why other files
// don't give this error.

import React from 'react';

const highlightButton = (e) => {
  const lbl = e.target.closest('div').querySelector('.c-choose__input-file-label');
  lbl.classList.add('pseudo-focus-button-label');
};

const unHighlightButton = (e) => {
  const lbl = e.target.closest('div').querySelector('.c-choose__input-file-label');
  lbl.classList.remove('pseudo-focus-button-label');
};

function UploadType(
  {
    logo, alt, name, description, description2, type, buttonFiles, clickedFiles, changed, clickedModal, buttonURLs,
  },
) {
  /*
  const {
    logo, alt, name, description, description2, type, buttonFiles, clickedFiles, changed, clickedModal, buttonURLs,
  } = props;
   */

  return (
    <section className="c-uploadwidget--data">
      <header>
        <img src={logo} alt={alt} />
        <h2>{name}</h2>
      </header>
      <b style={{textAlign: 'center'}}>
        {description}
        <br />
        {description2}
      </b>

      <div className="c-choose">
        <label htmlFor={type} aria-label={`upload ${type} files`} className="c-choose__input-file-label">{buttonFiles}</label>
        <input
          id={type}
          className="c-choose__input-file"
          type="file"
          onClick={clickedFiles}
          onChange={changed}
          onBlur={(e) => unHighlightButton(e)}
          onFocus={(e) => highlightButton(e)}
          multiple
        />
      </div>
      <button
        type="button"
        id={`${type}_manifest`}
        className="js-uploadmodal__button-show-modal"
        onClick={clickedModal}
      >
        {buttonURLs}
      </button>
    </section>
  );
}

export default UploadType;
