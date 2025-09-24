import React from 'react';

export {default} from './TitleImport';
export {default as TitlePreview} from './TitlePreview';

const nondescript = (t) => {
  /* eslint-disable max-len */
  const remainder = t.replace(/[^a-z0-9\s]/gi, '').replace(/\b(raw|data|dataset|datasets|dryad|fig|figure|figures|table|tables|file|supp|suppl|supplement|supplemental|extended|supplementary|supporting|manuscript|et al|the|of|for|in|from|to|with|s\d|f\d|t\d)\b/gi, '').trim();
  /* eslint-enable max-len */
  return remainder.split(/\s+/).length < 4;
};

export const titleFail = (resource) => {
  if (resource.title) {
    const p = document.createElement('p');
    p.innerHTML = resource.title;
    const title = p.textContent || p.innerText;
    if (nondescript(title)) {
      return (
        <p className="error-text" id="title_error">
          Your dataset title is not specific to your dataset. Use a descriptive title so your data can be discovered.
        </p>
      );
    }
    if (title === title.toUpperCase()) {
      return (
        <p className="error-text" id="title_error">
          All-caps titles are not allowed.
        </p>
      );
    }
  } else {
    return <p className="error-text" id="title_error">Title is required</p>;
  }
  return false;
};
