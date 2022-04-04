import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import DragonDrop from 'drag-on-drop';
import './Dragon.css';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';
import AuthorForm from './AuthorForm'

export default function Authors({resource, dryadAuthors}) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
  const dragonRef = useRef(null);

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
  const wrappingFunction = () => {
    updateOrderFromDom(authors);
  };

  // function relies on css class dd-list-item and data-id items in the dom for info, so render should make those
  function updateOrderFromDom(localAuthors) {
    const items = Array.from(dragonRef.current.querySelectorAll('li.dd-list-item'));

    const newOrder = items.map((item, idx) => ({id: parseInt(item.getAttribute('data-id')), order: idx}));

    // make into key/values with object id as key and order as value for fast lookup
    const newOrderObj = newOrder.reduce((obj, item) => {
      obj[item.id] = item.order;
      return obj;
    }, {});

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
    const newAuth = localAuthors.map((item) => ({...item, order: newOrderObj[item.id]}));

    // replace
    setAuthors(newAuth);
  }

  function deleteItem(id) {
    setAuthors(authors.filter((item) => (item.id !== id)));
  }

  function addItem() {
    const newId = (authors.length ? Math.max(...authors.map((auth) => auth.id)) + 1 : 1000);
    const lastOrder = (authors.length ? Math.max(...authors.map((auth) => auth.order)) + 1 : 0);
    const newAuthor = {id: newId, name: faker.name.findName(), order: lastOrder};
    setAuthors([...authors, newAuthor]);
  }

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
      <p id="global-help">
        Activate the reorder button and use the arrow keys to reorder the list or use your mouse to
        drag/reorder. Press escape to cancel the reordering.
        <span className="offscreen">Ensure screen reader is in focus mode.</span>
      </p>
      <ul className="dragon-drop-list" aria-labelledby="authors-head" ref={dragonRef}>
        {console.log('current authors in list from internal author data in react', authors)}
        {authors
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
                className="fa fa-bars handle"
                aria-labelledby={`author-button-${auth.id} author-text-${auth.id}`}
                id={`author-button-${auth.id}`}
              >
                <div className="offscreen">Reorder</div>
              </button>
              <AuthorForm dryadAuthor={auth} />
            </li>
          ))}
      </ul>
      <div>

        <a
        href="#"
        onClick={(e) => {
          e.preventDefault();
          addItem();
        }}
      >Add another author
      </a>
      </div>
      <br />
      <div>{authors.length} authors</div>
      <br />
    </section>
  );
}
