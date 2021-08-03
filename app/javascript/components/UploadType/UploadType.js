import React from 'react';

class UploadType extends React.Component {

  componentDidMount() {

    document.querySelectorAll('input.c-choose__input-file').forEach(item => {
      item.removeEventListener('focus', this.lblEventFocus);
      item.removeEventListener('blur', this.lblEventBlur);
      item.addEventListener('focus', this.lblEventFocus);
      item.addEventListener('blur', this.lblEventBlur);
    });
  }

  lblEventFocus = (e) => {
    const lbl = $(e.currentTarget).closest('div').find('label.c-choose__input-file-label');
    lbl.addClass('pseudo-focus-button-label');
  }

  lblEventBlur = (e) => {
    const lbl = $(e.currentTarget).closest('div').find('label.c-choose__input-file-label');
    lbl.removeClass('pseudo-focus-button-label');
  }

  render() {
    return (
        <section className="c-uploadwidget--data">
          <header>
            <img src={this.props.logo} alt={this.props.alt}/>
            <h2>{this.props.name}</h2>
          </header>
          <b style={{textAlign: 'center'}}>{this.props.description}</b>

          <div className="c-choose">
            <label htmlFor={this.props.type} aria-label={`upload ${this.props.type} files`} className="c-choose__input-file-label">{this.props.buttonFiles}</label>
            <input id={this.props.type} className="c-choose__input-file" type='file' onClick={this.props.clickedFiles}
                   onChange={this.props.changed} multiple={true}/>
          </div>
          <button id={this.props.type + '_manifest'} className="js-uploadmodal__button-show-modal"
                  onClick={this.props.clickedModal}>{this.props.buttonURLs}</button>
        </section>
    );
  }
}

export default UploadType;