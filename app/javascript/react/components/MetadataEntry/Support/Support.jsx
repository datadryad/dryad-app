import React from 'react';
import FacilityForm from './FacilityForm';
import Funders from './Funders';

export default function Support({current, resource, setResource}) {
  return (
    <>
      <FacilityForm resource={resource} setResource={setResource} />
      <div className="drag-instruct">
        <h3 id="funders-head" style={{marginTop: 0}}>Funding</h3>
        <p>Drag <i className="fa-solid fa-bars-staggered" role="img" aria-label="handle button" /> to reorder</p>
      </div>
      <Funders current={current} resource={resource} setResource={setResource} />
    </>
  );
}
