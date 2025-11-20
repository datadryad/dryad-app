import React, {Fragment, useRef, useEffect} from 'react';
import axios from 'axios';
import {ExitIcon} from '../../ExitButton';

const nameit = (name, arr) => {
  const plural = !['software', 'supplemental_information'].includes(name) && arr.length > 1 ? 's' : '';
  const upper = name.charAt(0).toUpperCase() + name.slice(1);
  return `${upper.replace('_', ' ')}${plural}`;
};

const groupBy = (arr, callback) => arr.reduce((acc = {}, ...args) => {
  const key = callback(...args);
  if (!acc[key]) acc[key] = [];
  acc[key].push(args[0]);
  return acc;
}, {});

function WorksList({identifiers, previous, curator}) {
  const works = groupBy(identifiers, ({work_type}) => work_type);
  const icons = {
    article: 'far fa-newspaper',
    dataset: 'fas fa-table',
    software: 'fas fa-code-branch',
    preprint: 'fas fa-receipt',
    supplemental_information: 'far fa-file-lines',
    data_management_plan: 'fas fa-list-check',
  };
  if (identifiers.length > 0) {
    return (
      <>
        <h2 style={{marginBottom: '-1rem'}}>Related works</h2>
        {Object.keys(works).map((type) => (
          <Fragment key={type}>
            <h3>{nameit(type, works[type])}</h3>
            <ul className="o-list">
              {works[type].map((w) => {
                const prev = previous?.find((r) => r.related_identifier === w.related_identifier);
                return (
                  <li key={w.id}>
                    <a
                      href={w.related_identifier}
                      target="_blank"
                      rel="noreferrer"
                      className={previous && (!prev || prev.work_type !== w.work_type) ? 'ins' : ''}
                    >
                      <i className={icons[type]} aria-hidden="true" style={{marginRight: '.5ch'}} />{w.related_identifier}<ExitIcon />
                    </a>
                    {curator && !w.verified && (
                      <i className="fas fa-link-slash unmatched-icon" role="note" aria-label="Unverified link" title="Unverified link" />
                    )}
                  </li>
                );
              })}
            </ul>
          </Fragment>
        ))}
        {previous?.map((p) => {
          if (identifiers.some((w) => w.related_identifier === p.related_identifier)) return null;
          return <del style={{display: 'block'}} key={p.id}>p.related_identifier</del>;
        })}
      </>
    );
  }
  return null;
}

export default function WorksPreview({resource, previous, curator}) {
  const ris = resource.related_identifiers.filter((ri) => ri.work_type !== 'primary_article' && !!ri.related_identifier);
  const pRis = previous?.related_identifiers.filter((ri) => ri.work_type !== 'primary_article' && !!ri.related_identifier);
  const colRef = useRef(null);

  if (resource.resource_type.resource_type === 'collection') {
    const cols = ris.filter((r) => r.relation_type === 'haspart');
    const prev = pRis?.related_identifiers?.filter((r) => r.relation_type === 'haspart');
    const other = ris.filter((r) => r.relation_type !== 'haspart');
    const preOther = pRis?.filter((r) => r.relation_type !== 'haspart');

    const getCollection = () => {
      axios.get(`/resources/${resource.id}/display_collection`).then((data) => {
        colRef.current.innerHTML = data.data;
        colRef.current.querySelectorAll('a').forEach((l) => l.setAttribute('target', '_blank'));
        if (previous) {
          cols.forEach((w) => {
            if (!prev.some((p) => p.related_identifier === w.related_identifier)) {
              colRef.current.getElementById(`col${w.id}`).classList.add('ins');
            }
          });
          prev.forEach((w) => {
            if (!cols.some((c) => c.related_identifier === w.related_identifier)) {
              const del = document.createElement('del');
              del.style.display = 'block';
              del.innerHTML = w.related_identifier;
              colRef.current.append(del);
            }
          });
        }
      });
    };

    useEffect(() => {
      if (colRef.current) {
        getCollection();
      }
    }, [resource, colRef]);

    return (
      <>
        <h2>Collected datasets</h2>
        <div ref={colRef} />
        <WorksList identifiers={other} previous={preOther} curator={curator} />
      </>
    );
  }
  return <WorksList identifiers={ris} previous={pRis} curator={curator} />;
}
