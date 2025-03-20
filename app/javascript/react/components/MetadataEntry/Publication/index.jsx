import React from 'react';
import {titleCase} from '../../../../lib/title-case';

export {default} from './Publication';
export {default as PubPreview} from './PubPreview';

const nondescript = (t) => {
  /* eslint-disable max-len */
  const remainder = t.replace(/[^a-z0-9\s]/gi, '').replace(/\b(raw|data|dataset|dryad|fig|figure|figures|table|tables|file|supp|suppl|supplement|supplemental|extended|supplementary|supporting|et al|the|of|for|in|from|to|s\d|f\d|t\d)\b/gi, '').trim();
  /* eslint-enable max-len */
  return remainder.split(/\s/).length < 4;
};

const capitals = (t) => {
  if (t === t.toUpperCase()) return 'All-caps titles are not allowed.';
  if (t.match(/\b[A-Z].*?\b/g)?.length > t.split(/\s/).length * 0.6) return 'Sentence case is preferred for titles.';
  return false;
};

const validPrimary = (r, t = 'primary_article') => {
  const p = r.related_identifiers.find((ri) => ri.work_type === t);
  if (!p) return false;
  return /^https:\/\/doi\.org\/10\.\d{4,9}\/[-._;()/:a-zA-Z0-9]+$/.test(p.related_identifier);
};

const copyTitle = (e) => {
  const copyButton = e.currentTarget.firstElementChild;
  const title = e.currentTarget.previousSibling.textContent;
  navigator.clipboard.writeText(title).then(() => {
    // Successful copy
    copyButton.parentElement.setAttribute('title', 'Title copied');
    copyButton.classList.remove('fa-paste');
    copyButton.classList.add('fa-check');
    copyButton.innerHTML = '<span class="screen-reader-only">Title copied</span>';
    setTimeout(() => {
      copyButton.parentElement.setAttribute('title', 'Copy title');
      copyButton.classList.add('fa-paste');
      copyButton.classList.remove('fa-check');
      copyButton.innerHTML = '';
    }, 2000);
  });
};

export const publicationPass = (resource) => !!resource.identifier.import_info || !!resource.title;

export const publicationFail = (resource, review) => {
  const {import_info} = resource.identifier;
  if (!!import_info || review) {
    if (resource.title) {
      if (nondescript(resource.title)) {
        return (
          <p className="error-text" id="title_error">
            Your dataset title is not specific to your dataset. Use a descriptive title so your data can be discovered.
          </p>
        );
      }
      if (capitals(resource.title)) {
        return (
          <>
            <p className="error-text" id="title_error">
              {capitals(resource.title)} Please correct your dataset title to sentence case, which could look like:
            </p>
            <div className="callout warn">
              <p><span>{titleCase(resource.title, {sentenceCase: true})}</span>
                <span
                  className="copy-icon"
                  role="button"
                  tabIndex="0"
                  aria-label="Copy title"
                  title="Copy title"
                  onClick={copyTitle}
                  onKeyDown={(e) => {
                    if (e.key === ' ' || e.key === 'Enter') {
                      copyTitle(e);
                    }
                  }}
                ><i className="fa fa-paste" role="status" />
                </span>
              </p>
            </div>
          </>
        );
      }
    } else {
      return <p className="error-text" id="title_error">Title is required</p>;
    }
    const {publication_name, manuscript_number} = resource.resource_publication;
    const {publication_name: preprint_server} = resource.resource_preprint || {};
    if (['manuscript', 'published'].includes(import_info) && !publication_name) {
      return (
        <p className="error-text" id="journal_error">The journal of the related publication is required</p>
      );
    }
    if (import_info === 'manuscript' && !manuscript_number) {
      return (
        <p className="error-text" id="msid_error">The manuscript number is required</p>
      );
    }
    if (import_info === 'published' && !validPrimary(resource)) {
      return (
        <p className="error-text" id="doi_error">A valid DOI for the article is required</p>
      );
    }
    if (import_info === 'preprint' && !preprint_server) {
      return (
        <p className="error-text" id="journal_error">The server of the related publication is required</p>
      );
    }
    if (import_info === 'preprint' && !validPrimary(resource, 'preprint')) {
      return (
        <p className="error-text" id="doi_error">A valid DOI for the preprint is required</p>
      );
    }
  }
  return false;
};
