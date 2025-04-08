import React, {
  useState, useRef, useEffect, useId,
} from 'react';
import HtmlDiff from 'htmldiff-js';

export default function HTMLDiffer({current, previous}) {
  const [showFinal, setShowFinal] = useState(false);
  const ref = useRef(null);
  const preRef = useRef(null);
  const diffRef = useRef(null);
  const refId = useId();
  const diffRefId = useId();

  useEffect(() => {
    if (ref.current && preRef.current && diffRef.current) {
      ref.current.innerHTML = current;
      preRef.current.innerHTML = previous;
      diffRef.current.innerHTML = HtmlDiff.execute(preRef.current.innerHTML, ref.current.innerHTML);
    }
  }, [ref, preRef, diffRef]);

  return (
    <>
      <div className="input-line" style={{display: 'inline-flex', gap: '1ch', marginBottom: '1rem'}} role="group" aria-label="Track changes">
        <button
          type="button"
          className="diff-toggle"
          aria-current={!showFinal}
          aria-controls={diffRefId}
          aria-disabled={!showFinal || null}
          onClick={() => setShowFinal(false)}
        >
          View changes
        </button>
        <button
          type="button"
          className="diff-toggle"
          aria-current={showFinal}
          aria-controls={refId}
          aria-disabled={showFinal || null}
          onClick={() => setShowFinal(true)}
        >
          View final
        </button>
      </div>
      <div ref={ref} hidden={!showFinal} id={refId} />
      <div ref={preRef} hidden />
      <div ref={diffRef} hidden={showFinal} id={diffRefId} />
    </>
  );
}
