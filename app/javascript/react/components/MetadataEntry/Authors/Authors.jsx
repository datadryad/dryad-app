import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import DragonDropList, {DragonListItem, orderedItems} from '../DragonDropList';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import AuthorForm from './AuthorForm';
import OrcidInfo from './OrcidInfo';

export default function Authors({
  resource, setResource, admin, ownerId,
}) {
  const [authors, setAuthors] = useState(resource.authors);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const lastOrder = () => (authors.length ? Math.max(...authors.map((auth) => auth.author_order)) + 1 : 0);

  const blankAuthor = {
    author_first_name: '',
    author_last_name: '',
    author_email: '',
    author_orcid: null,
    resource_id: resource.id,
  };

  const addNewAuthor = () => {
    const authorJson = {authenticity_token, author: {...blankAuthor, author_order: lastOrder()}};
    axios.post(
      '/stash_datacite/authors/create',
      authorJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure from authors create');
      }
      setAuthors((a) => [...a, data.data]);
    });
  };

  const updateItem = (author) => {
    showSavingMsg();
    return axios.patch(
      '/stash_datacite/authors/update',
      {authenticity_token, author},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from author save');
      }
      setAuthors((as) => as.map((a) => (a.id === author.id ? data.data : a)));
      showSavedMsg();
    });
  };

  const removeItem = (id, resource_id) => {
    showSavingMsg();
    const submitVals = {authenticity_token, author: {id, resource_id}};
    axios.delete(`/stash_datacite/authors/${id}/delete`, {
      data: submitVals,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure from authors delete');
      }
      showSavedMsg();
    });
    setAuthors((a) => a.filter((item) => (item.id !== id)));
  };

  useEffect(() => {
    setResource((r) => ({...r, authors}));
  }, [authors]);

  return (
    <>
      <h2 id="authors-head">Authors</h2>
      <DragonDropList model="author" typeName="author" items={authors} path="/stash_datacite/authors/reorder" setItems={setAuthors}>
        {orderedItems({items: authors, typeName: 'author'}).map((author) => (
          <DragonListItem key={author.id} item={author} typeName="author">
            <AuthorForm author={author} update={updateItem} remove={removeItem} ownerId={ownerId} />
            <div className="input-line" style={{marginLeft: '38px', marginTop: '1em'}}>
              <OrcidInfo author={author} curator={admin} ownerId={ownerId} />
              <div className="radio_choice" style={{marginLeft: 'auto'}}>
                <label title={!author.email ? 'Author email must be entered' : null}>
                  <input
                    type="checkbox"
                    defaultChecked={author.corresp}
                    disabled={!author.author_email}
                    onChange={(e) => updateItem({...author, corresp: e.target.checked})}
                  />
                  Display email
                </label>
              </div>
            </div>
          </DragonListItem>
        ))}
      </DragonDropList>
      <div style={{textAlign: 'right'}}>
        <button
          className="o-button__plain-text1"
          type="button"
          onClick={addNewAuthor}
        >
          + Add author
        </button>
      </div>
    </>
  );
}

Authors.propTypes = {
  resource: PropTypes.object.isRequired,
  admin: PropTypes.bool.isRequired,
  ownerId: PropTypes.number.isRequired,
};
