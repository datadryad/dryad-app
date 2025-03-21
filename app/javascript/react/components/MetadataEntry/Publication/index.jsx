import React from 'react';

export {default} from './Publication';
export {default as PubPreview} from './PubPreview';

const nondescript = (t) => {
  /* eslint-disable max-len */
  const remainder = t.replace(/[^a-z0-9\s]/gi, '').replace(/\b(raw|data|dataset|dryad|fig|figure|figures|table|tables|file|supp|suppl|supplement|supplemental|extended|supplementary|supporting|et al|the|of|for|in|from|to|s\d|f\d|t\d)\b/gi, '').trim();
  /* eslint-enable max-len */
  return remainder.split(/\s/).length < 4;
};

const validPrimary = (r, t = 'primary_article') => {
  const p = r.related_identifiers.find((ri) => ri.work_type === t);
  if (!p) return false;
  return /^https:\/\/doi\.org\/10\.\d{4,9}\/[-._;()/:a-zA-Z0-9]+$/.test(p.related_identifier);
};

export const publicationPass = (resource) => !!resource.identifier.import_info || !!resource.title;

export const publicationFail = (resource, review) => {
  const {import_info} = resource.identifier;
  if (!!import_info || review) {
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
    if (resource.title) {
      if (nondescript(resource.title)) {
        return (
          <p className="error-text" id="title_error">
            Your dataset title is not specific to your dataset. Use a descriptive title so your data can be discovered.
          </p>
        );
      }
      if (resource.title === resource.title.toUpperCase()) {
        return (
          <p className="error-text" id="title_error">
            All-caps titles are not allowed.
          </p>
        );
      }
    } else {
      return <p className="error-text" id="title_error">Title is required</p>;
    }
  }
  return false;
};
