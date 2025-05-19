import React, {useState, useRef, useEffect} from 'react';
import axios from 'axios';
import HTMLDiffer from '../HTMLDiffer';

export default function ReadMePreview({resource, previous, curator}) {
  const [current, setCurrent] = useState(null);
  const [prevRM, setPrevRM] = useState(null);
  const readmeRef = useRef(null);
  const readme = resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const prev = previous?.descriptions.find((d) => d.description_type === 'technicalinfo')?.description;
  const diff = previous && readme !== prev;

  const getREADME = () => {
    axios.get(`/resources/${resource.id}/display_readme`).then((data) => {
      if (diff && curator) setCurrent(data.data || '<div></div>');
      else if (readmeRef.current) readmeRef.current.append(document.createRange().createContextualFragment(data.data));
    });
    if (diff && curator) {
      axios.get(`/resources/${previous.id}/display_readme`).then((data) => {
        setPrevRM(data.data || '<div></div>');
      });
    }
  };

  useEffect(() => {
    if (readmeRef.current) {
      getREADME();
    }
  }, [resource, readmeRef]);

  if (readme) {
    return (
      <div ref={readmeRef}>
        {diff && (
          <>
            <ins />
            {curator && prevRM && current && (<HTMLDiffer current={current} previous={prevRM} />)}
          </>
        )}
      </div>
    );
  }
  if (prev) {
    return <del>README removed</del>;
  }
  return null;
}
