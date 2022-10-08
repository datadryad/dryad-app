import React from 'react';

import Url from './Url';

const failed_url_list = ({failedUrls, clicked}) => (
  <div>
    <h1 className="o-heading__level2">Validation Status</h1>
    {failedUrls.map((url, index) => {
      // key made from URL + count of preceding duplicates
      const key = url + failedUrls.slice(0, index).filter((u) => u === url).length;
      return (
        <Url
          key={key}
          click={() => clicked(index)}
          url={url}
        />
      );
    })}
  </div>
);

export default failed_url_list;
