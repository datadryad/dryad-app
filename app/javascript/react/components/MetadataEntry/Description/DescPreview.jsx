import React, {useRef, useEffect} from 'react';
import {formatSizeUnits} from '../../../../lib/utils';

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

export default function DescPreview({resource, previous}) {
  const abstract = resource.descriptions.find((d) => d.description_type === 'abstract')?.description;
  const methods = resource.descriptions.find((d) => d.description_type === 'methods')?.description;
  const usage = resource.descriptions.find((d) => d.description_type === 'other')?.description;
  const cedar = resource.cedar_json ? new Blob([resource.cedar_json]) : '';

  const prevA = previous?.descriptions.find((d) => d.description_type === 'abstract')?.description;
  const prevM = previous?.descriptions.find((d) => d.description_type === 'methods')?.description;
  const prevU = previous?.descriptions.find((d) => d.description_type === 'other')?.description;

  return (
    <>
      {previous && abstract !== prevA && <p className="del ins">Abstract changed</p>}
      {!!abstract && (
        <>
          <h3 className="o-heading__level2">Abstract</h3>
          <WrapTables html={abstract} />
        </>
      )}
      {previous && methods !== prevM && <p className="del ins">Methods changed</p>}
      {!!methods && (
        <>
          <h3 className="o-heading__level2">Methods</h3>
          <WrapTables html={methods} />
        </>
      )}
      {previous && usage !== prevU && <p className="del ins">Usage notes changed</p>}
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
      {previous && previous.cedar_json !== resource.cedar_json && <p className="del ins">CEDAR file changed</p>}
    </>
  );
}
