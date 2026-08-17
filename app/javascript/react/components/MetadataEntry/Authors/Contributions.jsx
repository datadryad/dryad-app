import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {ExitIcon} from '../../ExitButton';
import OrcidInfo from './OrcidInfo';

const fullname = (author) => [author?.author_org_name, author?.author_first_name, author?.author_last_name].filter(Boolean).join(' ');

function ContributionForm({author, roleList, updateItem}) {
  const setOption = (e) => {
    const checked = e.currentTarget.querySelectorAll('input:checked');
    const selected = [...checked].map((i) => ({id: i.value}));
    const a = structuredClone(author)
    a.credit_roles = selected
    updateItem(a)
  };

  return (
    <fieldset className="input-line" aria-label="Select author contributions" onChange={setOption} aria-errormessage="author_role_error">
      {roleList.map((r) => (
        <span className="radio_choice" key={r.credit_id}>
          <label>
            <input type="checkbox" name="credit_id" value={r.id} defaultChecked={author.credit_roles.map((c) => c.id).includes(r.id)} />
            {r.credit_role}
          </label>
        </span>
      ))}
    </fieldset>
  )
}

export default function Contributions({authors, updateItem}){
  const [hideKey, showKey] = useState(true);
  const [roleList, setRoleList] = useState([]);

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/credit_roles').then((data) => {
        setRoleList(data.data);
      });
    }
    getList();
  }, []);

  if (!roleList.length) {
    return (
      <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>
    )
  }

  return (
    <>
      <p>Select the appropriate <a href="https://credit.niso.org/" target="blank">CRediT roles<ExitIcon/></a> for each author on this data submission. If a role for any author is selected, each author must have at least one role. Not every role must be used.</p>
      <button type="button" className="o-button__plain-textlink" style={{paddingLeft: 0}} aria-controls="credit-defs" aria-expanded={!hideKey} 
        onClick={()=>showKey(!hideKey)}>
        Data submission CRediT role definitions
        <i className={`fa fa-caret-${hideKey ? 'right' : 'down'}`} aria-hidden="true" style={{marginLeft: '.35ch'}}/>
      </button>
      <dl id="credit-defs" hidden={hideKey || null}>
        {roleList.map((r) => (
          <div key={r.credit_id}>
            <dt>{r.credit_role}</dt>
            <dd>{r.description}.</dd>
          </div>
        ))}
      </dl>
      {authors.map(author => (
        <div className="author-form aff-form" key={author.id}>
          <div className="input-line">
            {fullname(author)}
            <OrcidInfo author={author} curator={false} />
          </div>
          <ContributionForm {...{author, roleList, updateItem}} />
        </div>
      ))}
    </>
  )
}