import React from 'react';
import FacilityForm from './FacilityForm';
import Funders from './Funders';

export default function Support({resource, setResource}) {
  return (
    <>
      <h2>Support</h2>
      <FacilityForm resource={resource} setResource={setResource} />
      <div className="drag-instruct">
        <h3 id="funders-head" style={{marginTop: 0}}>Funding</h3>
        <p>Drag <i className="fa-solid fa-bars-staggered" role="img" aria-label="handle button" /> to reorder</p>
      </div>
      <Funders resource={resource} setResource={setResource} />
    </>
  );
}
