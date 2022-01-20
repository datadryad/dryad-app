import React from 'react';

const highlightButton = (e) => {
  const lbl = e.target.closest('div').querySelector('.c-choose__input-file-label');
  lbl.classList.add('pseudo-focus-button-label');
};

const unHighlightButton = (e) => {
  const lbl = e.target.closest('div').querySelector('.c-choose__input-file-label');
  lbl.classList.remove('pseudo-focus-button-label');
};

class UploadType extends React.Component {
  render() {
    return (
      <section className="c-uploadwidget--data">
        <header>
          <img src={this.props.logo} alt={this.props.alt} />
          <h2>{this.props.name}</h2>
        </header>
        <b style={{ textAlign: 'center' }}>
          {this.props.description}
          <br />
          {this.props.description2}
        </b>

        <div className="c-choose">
          <label htmlFor={this.props.type} aria-label={`upload ${this.props.type} files`} className="c-choose__input-file-label">{this.props.buttonFiles}</label>
          <input
            id={this.props.type}
            className="c-choose__input-file"
            type="file"
            onClick={this.props.clickedFiles}
            onChange={this.props.changed}
            onBlur={(e) => unHighlightButton(e)}
            onFocus={(e) => highlightButton(e)}
            multiple
          />
        </div>
        <button
          id={`${this.props.type}_manifest`}
          className="js-uploadmodal__button-show-modal"
          onClick={this.props.clickedModal}
        >
          {this.props.buttonURLs}
        </button>
      </section>
    );
  }
}

export default UploadType;
