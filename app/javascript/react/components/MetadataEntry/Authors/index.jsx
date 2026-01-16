import React from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';
import {orderedItems} from '../DragonDropList';

export {default} from './Authors';
export {default as AuthPreview} from './AuthPreview';

const checkName = (a) => [a.author_first_name, a.author_last_name, a.author_org_name].filter(Boolean).join(' ').toLowerCase();

export const authorCheck = (resource) => {
  const {authors: auths, users} = resource;
  const authors = orderedItems({items: auths, typeName: 'author'});
  const submitter = authors.find((a) => a.author_orcid === users.find((u) => u.role === 'submitter')?.orcid);
  if (!submitter) {
    return (
      <p className="error-text" id="submitter_error">A submitting author is required</p>
    );
  }
  if (!submitter.author_email) {
    const ind = authors.filter((a) => a.author_org_name === null).findIndex((a) => a.id === submitter.id);
    return (
      <p className="error-text" id="author_email_error" data-index={ind}>Submitting author email is required</p>
    );
  }
  const fnameErr = authors.findIndex((a) => !a.author_first_name && !a.author_org_name);
  if (fnameErr >= 0) {
    return (
      <p className="error-text" id="author_fname_error" data-index={fnameErr}>
        {upCase(ordinalNumber(fnameErr + 1))} author name is required. Fill in or delete the entry
      </p>
    );
  }
  const affErr = authors.findIndex((a) => !a.author_org_name && !a.affiliations?.[0]?.long_name);
  if (affErr >= 0) {
    const ind = authors.filter((a) => a.author_org_name === null).findIndex((a) => !a.affiliations?.[0]?.long_name);
    return (
      <p className="error-text" id="author_aff_error" data-index={ind}>{upCase(ordinalNumber(affErr + 1))} author affiliation is required</p>
    );
  }
  const dupeName = authors.findIndex((a, i) => authors.find((au, x) => (i === x ? false : checkName(a) === checkName(au))));
  if (dupeName >= 0) {
    const name = checkName(authors[dupeName]);
    const last = authors.findLastIndex((a) => checkName(a) === name);
    return (
      <p className="error-text" id="author_fname_error" data-index={last}>
        The {ordinalNumber(last + 1)} author&apos;s name is the same as the {ordinalNumber(dupeName + 1)} author. Is this a duplicate?
      </p>
    );
  }
  const dupeEmail = authors.findIndex((a, i) => authors.find((au, x) => (i === x ? false
    : a.author_email && au.author_email && a.author_email.toLowerCase() === au.author_email.toLowerCase())));
  if (dupeEmail >= 0) {
    const email = authors[dupeEmail].author_email;
    const last = authors.findLastIndex((a) => a.author_email === email);
    const ind = authors.filter((a) => a.author_org_name === null).findLastIndex((a) => a.author_email === email);
    return (
      <p className="error-text" id="author_email_error" data-index={ind}>
        The {ordinalNumber(last + 1)} author&apos;s email address is the same as the {ordinalNumber(dupeEmail + 1)} author. Is this a duplicate?
      </p>
    );
  }
  if (!authors.some((a) => a.corresp)) {
    return (
      <p className="error-text" id="author_corresp_error">At least 1 published email is required</p>
    );
  }
  return false;
};
