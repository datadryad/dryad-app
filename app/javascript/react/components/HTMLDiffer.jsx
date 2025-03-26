import React, {useState, useRef, useEffect} from 'react';
import HtmlDiff from 'htmldiff-js';

export default function HTMLDiffer({current, previous}) {
  const [showFinal, setShowFinal] = useState(false);
  const ref = useRef(null);
  const preRef = useRef(null);
  const diffRef = useRef(null);

  useEffect(() => {
    if (ref.current && preRef.current && diffRef.current) {
      ref.current.innerHTML = current;
      preRef.current.innerHTML = previous;
      diffRef.current.innerHTML = HtmlDiff.execute(preRef.current.innerHTML, ref.current.innerHTML);
    }
  }, [ref, preRef, diffRef]);

  return (
    <>
      <div className="input-line" style={{gap: '1ch', marginBottom: '1rem'}}>
        <button type="button" className="diff-toggle" onClick={() => setShowFinal(false)} disabled={!showFinal}>
          View changes
        </button>
        <button type="button" className="diff-toggle" onClick={() => setShowFinal(true)} disabled={showFinal}>
          View final
        </button>
      </div>
      <div ref={ref} hidden={!showFinal} />
      <div ref={preRef} hidden />
      <div ref={diffRef} hidden={showFinal} />
    </>
  );
}
