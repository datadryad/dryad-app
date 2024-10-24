import React from 'react';
import FacilityForm from './FacilityForm';
import Funders from './Funders';

export default function Support({resource, setResource}) {
  return (
    <>
      <h2>Support</h2>
      <FacilityForm resource={resource} setResource={setResource} />
      <h3 id="funders-head">Funding</h3>
      <Funders resource={resource} setResource={setResource} />
    </>
  );
}
