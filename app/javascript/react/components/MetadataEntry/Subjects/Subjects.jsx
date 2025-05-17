import React from 'react';
import ResearchDomain from './ResearchDomain';
import Keywords from './Keywords';

export default function Subjects({step, resource, setResource}) {
  return (
    <>
      <ResearchDomain step={step} resource={resource} setResource={setResource} />
      <Keywords resource={resource} setResource={setResource} />
    </>
  );
}
