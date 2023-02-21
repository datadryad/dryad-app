import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import DragonDrop from 'drag-on-drop';
import './Dragon.css';
import PropTypes from 'prop-types';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import AuthorForm from './AuthorForm';
import OrcidInfo from './OrcidInfo';

export default function Authors({
  resource, dryadAuthors, curator, icon, correspondingAuthorId,
}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const dragonRef = useRef(null);
  const oldOrderRef = useRef(null);

  const [authors, setAuthors] = useState(dryadAuthors);
  const [dragonDrop, setDragonDrop] = useState(null);

  /* need to set a ref so it doesn't reset to initial values and also keep updating this wrapping function that is used in the
     callback from the other library every time the authors change. the savedWrapper.current = wrappingFunction below.

     This is especially annoying and has to do with closures maintaining old state from initial load and mismatch between
     react and standard javascript code.

     See https://overreacted.io/making-setinterval-declarative-with-react-hooks/ or
     https://stackoverflow.com/questions/57847594/react-hooks-accessing-up-to-date-state-from-within-a-callback
     It will make your head hurt.
   */

  const savedWrapper = useRef();

  const toOrderObj = (orderArr) => orderArr.reduce((obj, item) => {
    obj[item.id] = item.author_order;
    return obj;
  }, {});

  // function relies on css class dd-list-item and data-id items in the dom for info, so render should make those
  function updateOrderFromDom(localAuthors) {
    oldOrderRef.current = authors.map((item) => ({id: item.id, author_order: item.author_order}));
    const items = Array.from(dragonRef.current.querySelectorAll('li.dd-list-item'));

    const newOrder = items.map((item, idx) => ({id: parseInt(item.getAttribute('data-id'), 10), author_order: idx}));

    // make into key/values with object id as key and order as value for fast lookup

    const newOrderObj = toOrderObj(newOrder);

    showSavingMsg();
    // update order in the database
    axios.patch(
      '/stash_datacite/authors/reorder',
      {...newOrderObj, authenticity_token: csrf},
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Accept: 'application/json',
        },
      },
    ).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from funders save');
      }

      showSavedMsg();
    });

    // duplicate authors list with updated order values reflecting new order
    const newAuth = localAuthors.map((item) => ({...item, author_order: newOrderObj[item.id]}));

    // replace
    setAuthors(newAuth);
  }

  const wrappingFunction = () => {
    updateOrderFromDom(authors);
  };

  const lastOrder = () => (authors.length ? Math.max(...authors.map((auth) => auth.author_order)) + 1 : 0);

  const blankAuthor = {
    author_first_name: '',
    author_last_name: '',
    author_email: '',
    author_orcid: null,
    resource_id: resource.id,
  };

  const addNewAuthor = () => {
    console.log(`${(new Date()).toISOString()}: Adding author`);

    const authorJson = {
      authenticity_token: csrf,
      author: {...blankAuthor, author_order: lastOrder()},
    };

    axios.post(
      '/stash_datacite/authors/create',
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
    console.log(`${(new Date()).toISOString()}: deleting author`);
    const trueDelPath = `/stash_datacite/authors/${id}/delete`;
    showSavingMsg();

    // requiring the resource like this is weird in a controller for a model that isn't a resource, but it's how it is set up

    const submitVals = {
      authenticity_token: csrf,
      author: {
        id,
        resource_id,
      },
    };
    axios.delete(trueDelPath, {
      data: submitVals,
      headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
    }).then((data) => {
      if (data.status !== 200) {
        console.log('Response failure not a 200 response from authors delete');
      } else {
        console.log('deleted from authors');
      }
      showSavedMsg();
    });
    setAuthors((prevState) => prevState.filter((item) => (item.id !== id)));
  };

  // to set up dragon drop or reinit on changes
  useEffect(() => {
    if (!dragonDrop) {
      console.log('initializing DragonDrop for first time');
      // the "announcement section below is to announce changes to screen readers
      const dragon = new DragonDrop(dragonRef.current, {
        handle: '.handle',
        announcement: {
          grabbed: (el) => `${el.querySelector('input').value} grabbed`,
          dropped: (el) => `${el.querySelector('input').value} dropped`,
          reorder: (el, items) => {
            const pos = items.indexOf(el) + 1;
            const text = el.querySelector('input').value;
            return `The rankings have been updated, ${text} is now ranked #${pos} out of ${items.length}`;
          },
          cancel: 'Reranking cancelled.',
        },
      });
      savedWrapper.current = wrappingFunction;
      dragon.on('dropped', () => {
        savedWrapper.current();
      });
      dragon.on('cancel', () => {
        // Dragon Drop has an old bug that still isn't fixed https://github.com/schne324/dragon-drop/issues/34
        // So this is an extremely ugly workaround to re-submit the old values again since it fires both dropped and cancel
        // for a cancel, so we can't really prevent the drop from happening to begin with so we just have to delay and revert it.
        // Sorry, this is really hacky, but I don't have time to rewrite their library.
        setTimeout(() => {
          console.log('old order--revert', oldOrderRef.current);
          const newOrderObj = toOrderObj(oldOrderRef.current);

          axios.patch(
            '/stash_datacite/authors/reorder',
            {...newOrderObj, authenticity_token: csrf},
            {
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                Accept: 'application/json',
              },
            },
          ).then((data) => {
            if (data.status !== 200) {
              console.log('Response failure not a 200 response from funders reversion save for canceling drag and drop');
            }
          });

          // duplicate authors list with updated order values reflecting new (old) order
          // const newAuth = localAuthors.map((item) => ({...item, author_order: newOrderObj[item.id]}));

          setAuthors((prevState) => prevState.map((item) => ({...item, author_order: newOrderObj[item.id]})));
        }, 1000);
      });

      setDragonDrop(dragon);

      // dragon.on('dropped', function (container, item) {updateOrderFromDom(dragonRef.current); });
    } else {
      console.log('reinitializing dragon drop with author updates');
      savedWrapper.current = wrappingFunction;
      dragonDrop.initElements(dragonRef.current);
    }
  }, [authors]);

  return (
    <section>
      <p id="global-help" className="offscreen">
        Activate the reorder button and use the arrow keys to reorder the list or use your mouse to
        drag/reorder. Press escape to cancel the reordering.
        <span>Ensure screen reader is in focus mode.</span>
      </p>
      <ul className="dragon-drop-list" aria-labelledby="authors-head" ref={dragonRef}>
        {authors
          .slice(0) // because, WTF, sort mutates the original array in place, slice(0) creates copy
          .sort((a, b) => {
            // sorts by id if order not present and gets around 0 being falsey in javascript
            if (a.author_order === undefined || a.author_order === null || b.author_order === undefined || b.author_order === null) {
              return a.id - b.id;
            }
            return a.author_order - b.author_order;
          })
          .map((auth) => (
            <li key={auth.id} className="dd-list-item" data-id={auth.id}>
              <button
                aria-describedby="global-help"
                type="button"
                className="fa-workaround handle c-input"
                aria-label="Drag to reorder this author"
                id={`author-button-${auth.id}`}
                style={{background: `url('${icon}') no-repeat`, boxShadow: 'none'}}
              >
                <div className="offscreen">Reorder</div>
              </button>
              <AuthorForm dryadAuthor={auth} removeFunction={removeItem} correspondingAuthorId={correspondingAuthorId} />
              <OrcidInfo dryadAuthor={auth} curator={curator} correspondingAuthorId={correspondingAuthorId} />
            </li>
          ))}
      </ul>
      <div>
        <button
          className="t-describe__add-button o-button__add"
          type="button"
          onClick={addNewAuthor}
        >
          Add author
        </button>
      </div>
    </section>
  );
}

Authors.propTypes = {
  resource: PropTypes.object.isRequired,
  dryadAuthors: PropTypes.array.isRequired,
  curator: PropTypes.bool.isRequired,
  icon: PropTypes.string.isRequired,
  correspondingAuthorId: PropTypes.number.isRequired,
};
