import React, {useRef, useEffect} from 'react';
import {formatSizeUnits} from '../../../../lib/utils';

export {default} from './DescriptionGroup';

export const abstractCheck = (resource, review) => {
  const anydesc = resource.descriptions.some((d) => !!d.description);
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract')?.description;
  if ((review || anydesc) && !abstract) {
    return (
      <p className="error-text" id="abstract_error">An abstract is required</p>
    );
  }
  return false;
};

function WrapTables({html}) {
  const wall = useRef(null);
  useEffect(() => {
    if (wall.current) {
      wall.current.innerHTML = html;
      wall.current.querySelectorAll('table').forEach((t) => {
        const wrapper = document.createElement('div');
        wrapper.classList.add('table-wrapper');
        wrapper.setAttribute('role', 'region');
        wrapper.setAttribute('tabindex', 0);
        wrapper.setAttribute('aria-label', 'Table');
        t.before(wrapper);
        wrapper.appendChild(t);
      });
    }
  }, [wall, html]);
  return (
    <div className="t-landing__text-wall" ref={wall} />
  );
}

export function DescPreview({resource}) {
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract')?.description;
  const methods = resource.descriptions.find((d) => d.description_type === 'methods')?.description;
  const usage = resource.descriptions.find((d) => d.description_type === 'other')?.description;
  const cedar = resource.cedar_json ? new Blob([resource.cedar_json]) : '';
  return (
    <>
      {!!abstract && (
        <>
          <h3 className="o-heading__level2">Abstract</h3>
          <WrapTables html={abstract} />
        </>
      )}
      {!!methods && (
        <>
          <h3 className="o-heading__level2">Methods</h3>
          <WrapTables html={methods} />
        </>
      )}
      {!!usage && (
        <>
          <h3 className="o-heading__level2">Usage notes</h3>
          <WrapTables html={usage} />
        </>
      )}
      {!!resource.cedar_json && (
        <div className="callout">
          <p>DisciplineSpecificMetadata.json <span className="file_size">{formatSizeUnits(cedar.size)}</span> file generated.</p>
        </div>
      )}
    </>
  );
}
