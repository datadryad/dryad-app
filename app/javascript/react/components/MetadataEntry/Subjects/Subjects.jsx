import React, {useState} from 'react';
import ResearchDomain from './ResearchDomain';
import Keywords from './Keywords';

export default function Subjects({
  current, resource, setResource, error,
}) {
  const [touched, setTouched] = useState(false);
  return (
    <>
      <ResearchDomain current={current} resource={resource} setResource={setResource} onBlur={() => setTouched(true)} />
      <Keywords resource={resource} setResource={setResource} onBlur={() => setTouched(true)} />
      <div role="alert">{touched && error}</div>
    </>
  );
}
