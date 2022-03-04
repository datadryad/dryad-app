import React from 'react';
import FunderForm from "./FunderForm";

function Funders({resourceId, contributors, createPath, updatePath}){

  const blankFunder = {id: null, contributor_name: '', contributor_type: 'funder', identifier_type: '',  name_identifier_id: ''}

  if(contributors.length < 1){
    contributors = [ blankFunder ];
  }

  return (
    <>
      {contributors.map(contrib =>
        <FunderForm
          resourceId={resourceId}
          contributor={contrib}
          createPath={createPath}
          updatePath={updatePath}
        />)}
    </>
  );
}

export default Funders;