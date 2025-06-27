import React from 'react';
import ResearchDomain from './ResearchDomain';
import Keywords from './Keywords';

export default function Subjects({current, resource, setResource}) {
  return (
    <>
      <ResearchDomain current={current} resource={resource} setResource={setResource} />
      <Keywords resource={resource} setResource={setResource} />
    </>
  );
}
