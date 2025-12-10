import React, {useRef, useEffect} from 'react';
import {formatSizeUnits, upCase} from '../../../../lib/utils';
import HTMLDiffer from '../../HTMLDiffer';

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

function DescSection({
  title, previous, current, prev, curator,
}) {
  const diff = previous && current !== prev;

  if (current) {
    return (
      <>
        {diff && <ins />}
        {diff && curator && (
          <>
            <h3 className="o-heading__level2" style={{display: 'inline', marginRight: '1ch'}}>{title}</h3>
            <HTMLDiffer current={current} previous={prev} />
          </>
        )}
        {(!diff || !curator) && (
          <>
            <h3 className="o-heading__level2">{title}</h3>
            <WrapTables html={current} />
          </>
        )}
      </>
    );
  }
  if (prev) {
    return <del>{title} removed</del>;
  }
  return null;
}

export default function DescPreview({resource, previous, curator}) {
  const descs = ['abstract', 'methods', 'other'];
  const cedar = resource.cedar_json?.json ? new Blob([resource.cedar_json.json]) : '';
  return (
    <>
      {descs.map((t) => (
        <DescSection
          key={t}
          title={t === 'other' ? 'Usage notes' : upCase(t)}
          current={resource?.descriptions?.find((d) => d.description_type === t)?.description}
          prev={previous?.descriptions?.find((d) => d.description_type === t)?.description}
          previous={!!previous}
          curator={curator}
        />
      ))}
      {!!resource.cedar_json?.json && (
        <div className="callout">
          <p>DisciplineSpecificMetadata.json <span className="file_size">{formatSizeUnits(cedar.size)}</span> file generated.</p>
        </div>
      )}
      {previous && JSON.stringify(previous.cedar_json?.json) !== JSON.stringify(resource.cedar_json?.json) && (
        <p className="del ins">CEDAR file changed</p>
      )}
    </>
  );
}
