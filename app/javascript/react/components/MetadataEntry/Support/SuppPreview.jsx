import React from 'react';

const cName = (name) => (name?.endsWith('*') ? name.slice(0, -1) : name);

export default function SuppPreview({resource, previous, curator}) {
  const facility = resource.contributors.find((c) => c.contributor_type === 'sponsor');
  const funders = resource.contributors.filter((c) => c.contributor_type === 'funder');
  const pFacility = previous?.contributors.find((c) => c.contributor_type === 'sponsor');
  const pFunders = previous?.contributors.filter((c) => c.contributor_type === 'funder');
  const delFunders = pFunders?.slice(funders?.length);
  return (
    <>
      {facility && facility.contributor_name && (
        <div className="o-metadata__group2-item">
          Research facility:{' '}
          {previous && facility.contributor_name !== pFacility?.contributor_name ? (
            <><ins>{facility.contributor_name}</ins>{pFacility?.contributor_name && <del>{pFacility.contributor_name}</del>}</>
          ) : facility.contributor_name}
          {curator && !facility.name_identifier_id && (
            <i
              className="fas fa-triangle-exclamation unmatched-icon"
              role="note"
              aria-label="Unmatched facility"
              title="Unmatched facility"
            />
          )}
        </div>
      )}
      {(!facility || !facility.contributor_name) && pFacility?.contributor_name && (
        <del>Research facility: {pFacility.contributor_name}</del>
      )}
      {funders.length > 0 && funders[0].contributor_name !== 'N/A' && (
        <>
          <h3 className="o-heading__level2">Funding</h3>
          <ul className="o-list">
            {funders.sort((a, b) => a.funder_order - b.funder_order).map((funder, i) => {
              const prev = pFunders?.[i];
              return (
                <li key={funder.id}>
                  <span>
                    {previous && cName(funder.contributor_name) !== cName(prev?.contributor_name) ? (
                      <ins>{cName(funder.contributor_name)}</ins>
                    ) : cName(funder.contributor_name) }
                    {curator && !funder.name_identifier_id && (
                      <i className="fas fa-triangle-exclamation unmatched-icon" role="note" aria-label="Unmatched funder" title="Unmatched funder" />
                    )}
                    {previous && cName(funder.contributor_name) !== cName(prev?.contributor_name) && cName(prev?.contributor_name) && (
                      <del>{cName(prev?.contributor_name)}</del>
                    )}
                  </span>
                  {funder.award_number && (
                    <>,{' '}
                      <span>
                        {previous && funder.award_number !== prev?.award_number ? (
                          <><ins>{funder.award_number}</ins>{prev?.award_number && <del>{prev?.award_number}</del>}</>
                        ) : funder.award_number}
                      </span>
                    </>
                  )}
                  {!funder.award_number && previous && prev?.award_number && <del>prev.award_number</del>}
                  {funder.award_description && (
                    <>:{' '}
                      <span>
                        {previous && funder.award_description !== prev?.award_description ? (
                          <><ins>{funder.award_description}</ins>{prev?.award_description && <del>{prev?.award_description}</del>}</>
                        ) : funder.award_description}
                      </span>
                    </>
                  )}
                  {!funder.award_description && previous && prev?.award_description && <del>prev.award_description</del>}
                  {funder.award_title && (
                    <>:{' '}
                      <span>
                        {previous && funder.award_title !== prev?.award_title ? (
                          <><ins>{funder.award_title}</ins>{prev?.award_title && <del>{prev?.award_title}</del>}</>
                        ) : funder.award_title}
                      </span>
                    </>
                  )}
                  {!funder.award_title && previous && prev?.award_title && <del>prev.award_title</del>}
                </li>
              );
            })}
          </ul>
        </>
      )}
      {previous && delFunders.length > 0 && delFunders[0].contributor_name !== 'N/A' && (
        <div className="del">
          <h3><del>Funding</del></h3>
          <ul className="o-list">
            {delFunders.map((f) => (
              <del>{f.contributor_name}{f.award_id ? `, ${f.award_id}` : ''}{f.award_description ? `: ${f.award_description}` : ''}</del>
            ))}
          </ul>
        </div>
      )}
    </>
  );
}
