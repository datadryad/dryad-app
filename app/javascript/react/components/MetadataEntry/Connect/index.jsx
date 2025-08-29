import React from 'react';
import {urlCheck} from '../RelatedWorks/RelatedWorksErrors';

export {default} from './Publication';
export {default as PubPreview} from './PubPreview';

const validPrimary = (r, t = 'primary_article') => {
  const p = r.related_identifiers.find((ri) => ri.work_type === t);
  if (!p) return false;
  return /^https:\/\/doi\.org\/10\.\d{4,9}\/[-._;()/:a-zA-Z0-9]+$/.test(p.related_identifier);
};

export const publicationPass = (resource) => resource.identifier.import_info
  || resource.resource_preprint?.publication_name
  || resource.resource_publication?.publication_name
  || resource.resource_publication?.manuscript_number
  || resource.related_identifiers.find((ri) => ri.work_type === 'primary_article');

export const publicationFail = (resource) => {
  const {import_info} = resource.identifier;
  const {publication_name, manuscript_number} = resource.resource_publication;
  const primary_article = resource.related_identifiers.find((ri) => ri.work_type === 'primary_article');
  if (manuscript_number && !publication_name) {
    return (
      <p className="error-text" id="journal_ms_error">The journal of the related publication is required</p>
    );
  }
  if (primary_article && !publication_name) {
    return (
      <p className="error-text" id="journal_published_error">The journal of the related publication is required</p>
    );
  }
  if (publication_name && !primary_article && !manuscript_number) {
    return (
      <p className="error-text" id="msid_error">A manuscript number or published article DOI is required</p>
    );
  }
  if (primary_article && !validPrimary(resource)) {
    return (
      <p className="error-text" id="doi_error">A valid DOI for the article is required</p>
    );
  }
  if (primary_article && !urlCheck(primary_article.related_identifier)) {
    return (
      <p className="error-text" id="published_doi_error">You have entered an invalid DOI or URL for a published article.</p>
    );
  }
  return false;
};
