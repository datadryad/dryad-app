import React, {useState, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {isEqual} from 'lodash';
import DragonDropList, {DragonListItem, orderedItems} from '../DragonDropList';
import {showSavedMsg, showSavingMsg, showModalYNDialog} from '../../../../lib/utils';
import AuthorForm from './AuthorForm';

export default function Authors({
  resource, setResource, user, current,
}) {
  const [users, setUsers] = useState(resource.users);
  const [authors, setAuthors] = useState(resource.authors);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const lastOrder = () => (authors.length ? Math.max(...authors.map((auth) => auth.author_order)) + 1 : 0);

  const blankAuthor = {
    author_first_name: '',
    author_last_name: '',
    author_org_name: null,
    author_email: '',
    author_orcid: null,
    resource_id: resource.id,
  };

  const addNewAuthor = (org) => {
    if (org) blankAuthor.author_org_name = '';
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
    setAuthors((a) => a.filter((item) => item.id !== id));
  };

  const inviteAuthor = (event, author, role) => {
    showSavingMsg();
    return axios.patch(
      '/stash_datacite/authors/invite',
      {authenticity_token, author, role},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      showSavedMsg();
      if (data.data) {
        event.target.disabled = true;
        event.target.hidden = true;
        event.target.parentElement.previousElementSibling.hidden = true;
        event.target.nextElementSibling.innerHTML = 'Close';
        // eslint-disable-next-line max-len
        document.getElementById(`invite-${author.id}-alert`).innerHTML = '<p>Collaboration invitation sent! Only one collaborator may edit the submission at a time. To save your work and end your editing session, click &nbsp; <b><i class="fas fa-floppy-disk"></i> Save &amp; exit</b> &nbsp; at the top of the screen</p>';
        document.getElementById(`invite-${author.id}-alert`).className = 'callout alt';
        document.getElementById(`invite-dialog${author.id}`).addEventListener('close', () => {
          setAuthors((as) => as.map((a) => (a.id === author.id ? data.data.author : a)));
          setUsers(() => data.data.users);
        });
      }
    });
  };

  useEffect(() => {
    if (!isEqual(resource.authors, authors) || !isEqual(resource.users, users)) {
      setResource((r) => ({...r, authors, users}));
    }
  }, [authors, users]);

  useEffect(() => {
    if (current) {
      setAuthors(resource.authors);
      setUsers(resource.users);
    }
  }, [current]);

  return (
    <>
      <p className="drag-instruct" style={{marginTop: '0'}}>
        <span>Drag <i className="fa-solid fa-bars-staggered" role="img" aria-label="handle button" /> to reorder</span>
      </p>
      <DragonDropList model="author" typeName="author" items={authors} path="/stash_datacite/authors/reorder" setItems={setAuthors}>
        {orderedItems({items: authors, typeName: 'author'}).map((author) => (
          <DragonListItem key={author.id} item={author} typeName="author">
            <AuthorForm author={author} users={users} update={updateItem} invite={inviteAuthor} user={user} />
            <button
              type="button"
              className="remove-record"
              onClick={() => {
                showModalYNDialog('Are you sure you want to remove this author?', () => {
                  removeItem(author.id, author.resource_id);
                  // deleteItem(auth.id);
                });
              }}
              aria-label="Remove author"
              title="Remove"
            >
              <i className="fas fa-trash-can" aria-hidden="true" />
            </button>
          </DragonListItem>
        ))}
      </DragonDropList>
      <div className="auth-buttons">
        <button type="button" className="o-button__plain-text1" onClick={() => addNewAuthor(false)}>
          + Add author
        </button>
        <i className="fas fa-slash" role="img" aria-label=" or " />
        <button type="button" className="o-button__plain-text4" onClick={() => addNewAuthor(true)}>
          + Add group author
        </button>
      </div>
    </>
  );
}

Authors.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
  user: PropTypes.object.isRequired,
};
