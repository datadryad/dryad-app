import React from 'react';

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
        <input
          id={type}
          className="c-choose__input-file"
          type="file"
          onClick={clickedFiles}
          onChange={changed}
          multiple
        />
        <label htmlFor={type} aria-label={`upload ${type} files`} className="c-choose__input-file-label">{buttonFiles}</label>
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
