import React, {useState} from 'react';
import FunderForm from "./FunderForm";

function Funders({resourceId, contributors, createPath, updatePath}){

  const blankFunder = {id: '', contributor_name: '', contributor_type: 'funder', identifier_type: '',  name_identifier_id: ''}

  const [funders, setFunders] = useState(contributors);

  if(funders.length < 1){
    setFunders([ blankFunder ]);
  }

  const removeItem = (i) => {
    console.log(`removing ${i}`);
    setFunders(funders.filter((item, idx) => (idx !== i)));
  }

  return (
    <>
      { console.log(funders) }
      {funders.map((contrib, i) => (
          <FunderForm
            key={i}
            resourceId={resourceId}
            contributor={contrib}
            createPath={createPath}
            updatePath={updatePath}
            removeFunction={ () => { removeItem(i) } } // hacky since I want to call this method with this value and not a closure
          />
        ))}
      <a href="#"
         className="t-describe__add-funder-button o-button__add"
         role="button"
         onClick={(e) => {
           e.preventDefault();
           setFunders( prev => [...prev, blankFunder]);
         }}
      >
        add another funder
      </a>
    </>
  );
}

export default Funders;