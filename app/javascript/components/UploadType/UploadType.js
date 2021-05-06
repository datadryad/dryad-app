import React from 'react';

const upload_type = (props) => {
    return (
        <section className="c-uploadwidget--data">
            <header>
                <img src={props.logo} alt={props.alt} />
                <h2>{props.name}</h2>
            </header>
            <b style={{textAlign: 'center'}}>{props.description}</b>

            <div className="c-choose">
                <label htmlFor={props.type} className="c-choose__input-file-label">{props.buttonFiles}</label>
                <input id={props.type} className="c-choose__input-file" type='file' onChange={props.changed} multiple={true} />
            </div>
            <button id={props.type + '_manifest'} className="js-uploadmodal__button-show-modal" onClick={props.clicked}>{props.buttonURLs}</button>
        </section>
    );
}

export default upload_type;