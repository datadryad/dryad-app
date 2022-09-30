import React from 'react';
import parse from 'html-react-parser';

const url = (props) => (
  <div className="c-manifest__item">
    <div className="c-manifest__url">{props.url.url}</div>
    <div className="c-manifest__error">{parse(props.url.error_message)}</div>
    <div className="c-manifest__action">
      {/* <a href="#!">Edit</a> */}
      <a href="#!" onClick={props.click}>Remove</a>
    </div>
  </div>
);

export default url;
