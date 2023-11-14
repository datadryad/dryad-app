import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import DragonDropList, {DragonListItem, orderedItems} from './DragonDropList';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import AuthorForm from './AuthorForm';
import OrcidInfo from './OrcidInfo';

export default function Authors({
  resource, dryadAuthors, curator, correspondingAuthorId, createPath, deletePath, reorderPath,
}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const [authors, setAuthors] = useState(dryadAuthors);

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
      createPath,
      authorJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't add new author from remote server");
        }
        setAuthors((prevState) => [...prevState, data.data]);
      });
  };

  const removeItem = (id, resource_id) => {
    const trueDelPath = deletePath.replace('id_xox', id);
    showSavingMsg();

    // requiring the resource like this is weird in a controller for a model that isn't a resource, but it's how it is set up
    const submitVals = {authenticity_token, author: {id, resource_id}};
    axios.delete(trueDelPath, {
      data: submitVals,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from authors delete');
      }
      showSavedMsg();
    });
    setAuthors((prevState) => prevState.filter((item) => (item.id !== id)));
  };

  return (
    <div>
      <DragonDropList model="author" typeName="author" items={authors} path={reorderPath} setItems={setAuthors}>
        {orderedItems({items: authors, typeName: 'author'}).map((author) => (
          <DragonListItem key={author.id} item={author} typeName="funder">
            <AuthorForm dryadAuthor={author} removeFunction={removeItem} correspondingAuthorId={correspondingAuthorId} />
            <OrcidInfo dryadAuthor={author} curator={curator} correspondingAuthorId={correspondingAuthorId} />
          </DragonListItem>
        ))}
      </DragonDropList>
      <button
        className="t-describe__add-button o-button__add"
        type="button"
        onClick={addNewAuthor}
      >
        Add author
      </button>
    </div>
  );
}

Authors.propTypes = {
  resource: PropTypes.object.isRequired,
  dryadAuthors: PropTypes.array.isRequired,
  curator: PropTypes.bool.isRequired,
  correspondingAuthorId: PropTypes.number.isRequired,
  createPath: PropTypes.string.isRequired,
  deletePath: PropTypes.string.isRequired,
  reorderPath: PropTypes.string.isRequired,
};
