import React, {useState, useEffect} from 'react';
import axios from 'axios';
import DragonDrop from 'drag-on-drop';
import {faker} from '@faker-js/faker';
import './Dragon.css';

export default function DragonTest1(){

  const nameArr = new Array(10).fill( true ).map((item, idx) => {
    return { id: idx + 1000, name: faker.name.findName(), order: idx }
  });

  const [authors, setAuthors] = useState(nameArr);
  // const [dragonDrop, setDragonDrop] = useState(null);

  // function relies on css class dd-list-item and data-id items in the dom for info, so render should make those
  function updateOrderFromDom(container) {
    const items = Array.from(container.querySelectorAll('li.dd-list-item'));

    const newOrder = items.map((item, idx) => {
      return { id: parseInt(item.getAttribute('data-id')), order: idx }
    });

    // make into key/values with object id as key and order as value for fast lookup
    const newOrderObj = newOrder.reduce( (obj, item) => {
      obj[item.id] = item.order;
      return obj;
    }, {});
    // console.log("new order object:", newOrderObj);

    // duplicate authors list with updated order values reflecting new order
    const newAuth = authors.map((item) => {
      return {...item, order: newOrderObj[item.id]}
    });

    // replace
    setAuthors(newAuth);
  }

  function deleteItem(id){
    setAuthors(authors.filter((item) => (item.id !== id)));
  }

  useEffect(() => {
    // do this after first render
    const ddAuthors = document.getElementById('dd-authors');

    // the "announcement section below is to announce changes to screen readers
    const dragon = new DragonDrop(ddAuthors, {
      handle: '.handle',
      announcement: {
        grabbed: el => `${el.querySelector('span').innerText} grabbed`,
        dropped: el => `${el.querySelector('span').innerText} dropped`,
        reorder: (el, items) => {
          console.log('reordered');
          const pos = items.indexOf(el) + 1;
          const text = el.querySelector('span').innerText;
          return `The rankings have been updated, ${text} is now ranked #${pos} out of ${items.length}`;
        },
        cancel: 'Reranking cancelled.'
      }
    });

    dragon.on('dropped', function (container, item) {
      // console.log('dropped: ', item);
      // console.log('container: ', container);
      updateOrderFromDom(container);
    });

  }, []);

  useEffect(() => {
    console.log('author list:', authors);
  }, [authors])

  return (
    <section>
      <h2 id="authors-head">Dragon Drop test component here</h2>
      <p id="global-help">
        Activate the reorder button and use the arrow keys to reorder the list or use your mouse to
        drag/reorder. Press escape to cancel the reordering.
        <span className="offscreen">Ensure screen reader is in focus mode.</span>
      </p>
      <ul className="dragon-drop-list" id="dd-authors" aria-labelledby="authors-head">
        {authors
            .sort((a, b) => {
              // sorts by id if order not present and gets around 0 being falsey in javascript
              if (a.order === undefined || a.order === null || b.order === undefined || b.order === null) {
                return a.order - b.order;
              }else{
                return a.id - b.id;
              }
            })
            .map((name) => (
          <li key={name.id} className="dd-list-item" data-id={name.id}>
            <button aria-describedby="global-help"
                    type="button"
                    className="fa fa-bars handle"
                    aria-labelledby={`author-button-${name.id} author-text-${name.id}`}
                    id={`author-button-${name.id}`}>
              <div className="offscreen">Reorder</div>
            </button>
            <span id={`author-text-${name.id}`}>{name.name}</span>&nbsp;
            <a href="#" onClick={() => deleteItem(name.id)}>delete</a>
          </li>
        ))}
      </ul>
      <div>{authors.length} authors</div>
    </section>
  );
}