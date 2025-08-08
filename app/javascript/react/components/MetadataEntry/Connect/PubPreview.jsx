import React from 'react';
import {ExitIcon} from '../../ExitButton';

export default function PubPreview({resource, previous, curator}) {
  const {publication_name, manuscript_number} = resource.resource_publication;
  const primary = resource.related_identifiers.find((ri) => ri.work_type === 'primary_article');
  const primary_article = primary?.related_identifier;
  const {publication_name: prev_pub, manuscript_number: prev_man} = previous?.resource_publication || {};
  const prev_prim = previous?.related_identifiers.find((ri) => ri.work_type === 'primary_article');
  const prev_art = prev_prim?.related_identifier;
  if (publication_name) {
    return (
      <p style={{
        display: 'flex', columnGap: '2ch', rowGap: '1ch', flexWrap: 'wrap',
      }}
      >
        <span>
          <b>Journal:</b>{' '}
          {previous && publication_name !== prev_pub ? (
            <><ins>{publication_name}</ins>{prev_pub && <del>{prev_pub}</del>}</>
          ) : publication_name}
        </span>
        {manuscript_number && (
          <span>
            <b>Manuscript:</b>{' '}
            {previous && manuscript_number !== prev_man ? (
              <><ins>{manuscript_number}</ins>{prev_man && <del>{prev_man}</del>}</>
            ) : manuscript_number}
          </span>
        )}
        {primary_article && (
          <span>
            <b>Primary article:</b>{' '}
            <a href={primary_article} target="_blank" rel="noreferrer" className={previous && primary_article !== prev_art ? 'ins' : null}>
              <i className="fas fa-newspaper" aria-hidden="true" style={{marginRight: '.5ch'}} />{primary_article}<ExitIcon />
            </a>
            {curator && !primary.verified && (
              <i className="fas fa-link-slash unmatched-icon" role="note" aria-label="Unverified link" title="Unverified link" />
            )}
            {previous && primary_article !== prev_art && prev_art && <del>{prev_art}</del>}
          </span>
        )}
      </p>
    );
  }
  return null;
}
