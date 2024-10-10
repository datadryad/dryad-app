import React, {Fragment} from 'react';
import {upCase, ordinalNumber} from '../../../../lib/utils';
import {orcidURL} from './OrcidInfo';

export {default} from './Authors';

export const authorCheck = (authors, id) => {
  if (!authors.find((a) => a.id === id)?.author_email) {
    return (
      <p className="error-text" id="author_email_error">Submitting author email is required</p>
    );
  }
  const fnameErr = authors.findIndex((a) => !a.author_first_name);
  if (fnameErr >= 0) {
    return (
      <p className="error-text" id="author_fname_error" data-index={fnameErr}>
        {upCase(ordinalNumber(fnameErr + 1))} author first name is required
      </p>
    );
  }
  const lnameErr = authors.findIndex((a) => !a.author_last_name);
  if (lnameErr >= 0) {
    return (
      <p className="error-text" id="author_lname_error" data-index={lnameErr}>
        {upCase(ordinalNumber(lnameErr + 1))} author last name is required
      </p>
    );
  }
  const affErr = authors.findIndex((a) => !a.affiliations[0]?.long_name);
  if (affErr >= 0) {
    return (
      <p className="error-text" id="author_aff_error" data-index={affErr}>{upCase(ordinalNumber(affErr + 1))} author affiliation is required</p>
    );
  }
  return false;
};

const affName = (aff) => {
  if (!aff.short_name && !aff.long_name) return '';
  const chosen_name = !aff.short_name ? aff.long_name.trim() : aff.short_name.trim();
  if (!/[a-zA-Z]/.test(chosen_name)) return '';
  return chosen_name.endsWith('*') ? chosen_name.slice(0, -1) : chosen_name;
};

export function AuthPreview({resource, admin}) {
  const {authors} = resource;
  const affs = authors.map((a) => a.affiliations).flat().reduce((arr, aff) => {
    if (affName(aff)) arr.push([aff.id, affName(aff), aff.ror_id]);
    return arr;
  }, []);
  return (
    <>
      <p className="o-metadata__author-list">
        {authors.map((author, i) => {
          const fullname = [author.author_first_name, author.author_last_name].filter(Boolean).join(' ');
          const citename = [author.author_last_name, author.author_first_name].filter(Boolean).join(', ');
          return (
            <Fragment key={author.id}>
              <span className="o-metadata__author">{citename}</span>
              {author.affiliations.map((a) => {
                const name = affName(a);
                if (name) {
                  return (
                    <a
                      key={a.id}
                      className="o-metadata__link"
                      aria-label={`Affiliation ${affs.findIndex((x) => x[0] === a.id) + 1}`}
                      href={`#aff${a.id}`}
                    >
                      {affs.findIndex((x) => x[0] === a.id) + 1}
                    </a>
                  );
                }
                return null;
              })}
              {author.author_email && (
                <a
                  href={`mailto:${author.author_email}`}
                  className="o-metadata__link"
                  aria-label={`Email ${fullname}`}
                  target="_blank"
                  title={author.author_email}
                  rel="noreferrer"
                >
                  <i className="fa fa-envelope" aria-hidden="true" />
                </a>
              )}
              {author.author_orcid && (
                <a
                  href={orcidURL(author.author_orcid)}
                  className="o-metadata__link"
                  target="_blank"
                  aria-label={`${fullname} ORCID profile (opens in new window)`}
                  title={`ORCID: ${author.author_orcid}`}
                  rel="noreferrer"
                >
                  <i className="fab fa-orcid" aria-hidden="true" />
                </a>
              )}
              {i < authors.length - 1 && '; '}
            </Fragment>
          );
        })}
      </p>
      {affs.length > 0 && (
        <div className="o-metadata__aff-list">
          <p role="heading" aria-level="2" style={{marginTop: '1em', fontSize: '1rem'}}>
            Author affiliations
          </p>
          <ol id="affiliation-list">
            {affs.map((aff) => (
              <li key={aff[0]} id={`aff${aff[0]}`}>
                {aff[1]}
                {admin && !aff[2] && (
                  <i
                    className="fas fa-triangle-exclamation unmatched-icon"
                    role="note"
                    aria-label="Unmatched affiliation"
                    title="Unmatched affiliation"
                  />
                )}
              </li>
            ))}
          </ol>
        </div>
      )}
    </>
  );
}
