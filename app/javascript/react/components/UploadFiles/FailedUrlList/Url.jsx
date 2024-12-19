import React from 'react';
import parse from 'html-react-parser';

const getErrorMessage = (url) => {
  switch (url.status_code) {
  case 200:
    return '';
  case 400:
    return 'The URL was not entered correctly. Be sure to use http:// or https:// to start all URLS';
  case 401:
    return 'The URL was not authorized for download.';
  case 403: case 404:
    return 'The URL was not found.';
  case 410:
    return 'The requested URL is no longer available.';
  case 411:
    return 'URL cannot be downloaded, please link directly to data file';
  case 414:
    return `The server will not accept the request, because the URL ${url.url} is too long.`;
  case 408: case 499:
    return 'The server timed out waiting for the request to complete.';
  case 409:
    return "You've already added this URL in this version.";
  case 481:
    return '<a href="/stash/web_crawling" target="_blank">Crawling of HTML files</a> isn\'t supported.';
  // case 500: case 501: case 502: case 503: case 504: case 505: case 506: case 507: case 508: case 509: case 510: case 511:
  default:
    return 'Encountered a remote server error while retrieving the request.';
  }
};

function Url({url, click}) {
  return (
    <div className="c-manifest__item">
      <div className="c-manifest__url">{url.url}</div>
      <div className="c-manifest__error">{parse(getErrorMessage(url))}</div>
      <div className="c-manifest__action">
        {/* <a href="#!">Edit</a> */}
        <a href="#!" onClick={click}>Remove</a>
      </div>
    </div>
  );
}

export default Url;
