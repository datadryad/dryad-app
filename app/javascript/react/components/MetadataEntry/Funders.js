import React, {useState} from 'react';
import FunderForm from "./FunderForm";
import {nanoid} from 'nanoid';

function Funders({resourceId, contributors, createPath, updatePath}){

  const blankFunder = () => {
     return {id: `new${nanoid()}`, contributor_name: '', contributor_type: 'funder', identifier_type: '',  name_identifier_id: ''};
  }

  const [funders, setFunders] = useState(contributors);

  if(funders.length < 1){
    setFunders([ blankFunder() ]);
  }

  const removeItem = (id) => {
    console.log(`removing ${id}`);
    setFunders(funders.filter((item) => (item.id !== id)));
  }

  return (
    <>
      { console.log(funders) }
      {funders.map((contrib, i) => (
          <FunderForm
            key={contrib.id}
            resourceId={resourceId}
            contributor={contrib}
            createPath={createPath}
            updatePath={updatePath}
            removeFunction={ () => { removeItem(contrib.id) } }
          />
        ))}
      <a href="#"
         className="t-describe__add-funder-button o-button__add"
         role="button"
         onClick={(e) => {
           e.preventDefault();
           setFunders( prev => [...prev, blankFunder() ]);
         }}
      >
        add another funder
      </a>
    </>
  );
}

export default Funders;