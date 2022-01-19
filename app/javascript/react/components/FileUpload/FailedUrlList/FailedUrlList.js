/* eslint-disable react/no-array-index-key */
// This is a bad practice, but not sure if another key is available and this is temporary display I believe

import React from 'react';

import Url from './Url/Url';

const failed_url_list = (props) => (
  <div>
    <h1 className="o-heading__level2">Validation Status</h1>
    {props.failedUrls.map((url, index) => (
      <Url
        key={index}
        click={() => props.clicked(index)}
        url={url}
      />
    ))}
  </div>
);

export default failed_url_list;
