import React, {Fragment} from 'react';
import {orcidURL} from './OrcidInfo';

const affName = (aff) => {
  if (!aff || (!aff.short_name && !aff.long_name)) return '';
  const chosen_name = !aff.short_name ? aff.long_name.trim() : aff.short_name.trim();
  if (!/[a-zA-Z]/.test(chosen_name)) return '';
  return chosen_name.endsWith('*') ? chosen_name.slice(0, -1) : chosen_name;
};

const getAffs = (ar) => ar.map((a) => a.affiliations).flat().reduce((arr, aff) => {
  if (affName(aff) && !arr.some((c) => aff.id === c[0])) arr.push([aff.id, affName(aff), aff.ror_id]);
  return arr;
}, []);

const fullname = (author) => [author?.author_first_name, author?.author_last_name].filter(Boolean).join(' ');
const citename = (author) => {
  if (author?.author_org_name) return author.author_org_name;
  return [author?.author_last_name, author?.author_first_name].filter(Boolean).join(', ');
};

export default function AuthPreview({resource, previous, admin}) {
  const {authors} = resource;
  const prev_auth = previous?.authors || [];
  const affs = getAffs(authors);
  const prev_affs = getAffs(prev_auth);
  const del_auth = prev_auth?.slice(authors?.length);
  const del_affs = prev_affs?.slice(affs?.length);
  return (
    <>
      <p className="o-metadata__author-list">
        {authors.sort((a, b) => a.author_order - b.author_order).map((author, i) => {
          const prev = prev_auth[i];
          return (
            <Fragment key={author.id}>
              {previous && citename(prev) !== citename(author) ? (
                <>
                  <span className="o-metadata__author ins">{citename(author)}</span>
                  {citename(prev) && <del>{citename(prev)}</del>}
                </>
              ) : (
                <span className="o-metadata__author">{citename(author)}</span>
              )}
              {author.affiliations.map((a, n) => {
                const name = affName(a);
                if (name) {
                  return (
                    <a
                      key={a.id}
                      className={`o-metadata__link ${previous && name !== affName(prev?.affiliations[n]) ? 'ins' : ''}`}
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
                <>
                  {author.corresp && (
                    <a
                      href={`mailto:${author.author_email}`}
                      className={`o-metadata__link ${previous && author.author_email !== prev?.author_email ? 'ins' : ''}`}
                      aria-label={`Email ${fullname(author)}`}
                      target="_blank"
                      title={author.author_email}
                      rel="noreferrer"
                    >
                      <i className="fa fa-envelope" aria-hidden="true" />
                    </a>
                  )}
                  {admin && !author.corresp && (
                    <sup title="Shown for admin">
                      {previous && author.author_email !== prev?.author_email ? <ins>{author.author_email}</ins> : author.author_email}
                    </sup>
                  )}
                </>
              )}
              {previous && author.author_email !== prev?.author_email && prev?.author_email && (
                <sup><del>{prev.author_email}</del></sup>
              )}
              {author.author_orcid && (
                <a
                  href={orcidURL(author.author_orcid)}
                  className={`o-metadata__link ${previous && author.author_orcid !== prev?.author_orcid ? 'ins' : ''}`}
                  target="_blank"
                  aria-label={`${fullname(author)} ORCID profile (opens in new window)`}
                  title={`ORCID: ${author.author_orcid}`}
                  rel="noreferrer"
                >
                  <i className="fab fa-orcid" aria-hidden="true" />
                </a>
              )}
              {previous && author.author_orcid !== prev?.author_orcid && prev?.author_orcid && (
                <sup><del>{prev.author_orcid}</del></sup>
              )}
              {i < authors.length - 1 && '; '}
            </Fragment>
          );
        })}
        {del_auth.length > 0 && del_auth.map((a, i) => <><del>{citename(a)}</del>{i < del_auth.length - 1 && '; '}</>)}
      </p>
      {affs.length > 0 && (
        <div className="o-metadata__aff-list">
          <p role="heading" aria-level="2" style={{marginTop: '1em', fontSize: '1rem'}}>
            Author affiliations
          </p>
          <ol id="affiliation-list">
            {affs.map((aff, i) => (
              <li key={aff[0]} id={`aff${aff[0]}`}>
                {previous && aff[1] !== prev_affs[i]?.[1] ? <ins>{aff[1]}</ins> : aff[1]}
                {admin && !aff[2] && (
                  <i
                    className="fas fa-triangle-exclamation unmatched-icon"
                    role="note"
                    aria-label="Unmatched affiliation"
                    title="Unmatched affiliation"
                  />
                )}
                {previous && aff[1] !== prev_affs[i]?.[1] && prev_affs[i]?.[1] && <del>{prev_affs[i][1]}</del>}
              </li>
            ))}
          </ol>
        </div>
      )}
      {previous && del_affs.length > 0 && (
        <div className="o-metadata__aff-list del">
          <p role="heading" aria-level="2" style={{marginTop: '1em', fontSize: '1rem'}}>
            <del>Author affiliations</del>
          </p>
          <ol style={{listStyle: ''}}>
            {del_affs.map((aff) => <li><del>{aff[1]}</del></li>)}
          </ol>
        </div>
      )}
    </>
  );
}
