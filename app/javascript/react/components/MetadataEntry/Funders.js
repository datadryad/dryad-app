import React, {useState} from 'react';
import FunderForm from "./FunderForm";
import {nanoid} from 'nanoid';
import axios from "axios";
import {showSavedMsg, showSavingMsg} from "../../../lib/utils";

function Funders({resourceId, contributors, createPath, updatePath, deletePath}){

  const blankFunder = () => {
     return {id: `new${nanoid()}`, contributor_name: '', contributor_type: 'funder', identifier_type: '',  name_identifier_id: ''};
  }

  const [funders, setFunders] = useState(contributors);

  if(funders.length < 1){
    setFunders([ blankFunder() ]);
  }

  const removeItem = (id) => {
    console.log(`removing ${id}`);
    const trueDelPath = deletePath.replace('id_xox', id);
    const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    showSavingMsg();

    // TODO: requiring the resource like this is weird in a controller for a model that isn't a resource
    if (!`${id}`.startsWith('new')) {
      const submitVals = {
        authenticity_token: csrf,
        contributor: {
          id: id,
          resource_id: resourceId
        }
      }
      axios.delete(trueDelPath, {
        data: submitVals,
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}
      })
          .then((data) => {
            if (data.status !== 200) {
              console.log('Response failure not a 200 response from funders save');
            } else {
              console.log('deleted from funders');
            }
            showSavedMsg();
          });
    }

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