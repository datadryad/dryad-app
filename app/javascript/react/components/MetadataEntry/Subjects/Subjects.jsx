import React from 'react';
import ResearchDomain from './ResearchDomain';
import Keywords from './Keywords';

export default function Subjects({resource, setResource}) {
  return (
    <>
      <ResearchDomain resource={resource} setResource={setResource} />
      <Keywords resource={resource} setResource={setResource} />
    </>
  );
}
