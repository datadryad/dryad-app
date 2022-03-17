import React, {useState, useEffect} from 'react';
import axios from 'axios';
import DragonDrop from 'drag-on-drop';
import {faker} from '@faker-js/faker';
import './Dragon.css';

export default function DragonTest1(){

  const nameArr = new Array(20).fill( true ).map((item, idx) => {
    return { id: idx + 1000, name: faker.name.findName(), order: idx }
  });

  useEffect(() => {
    // do this after first render
    const demo1 = document.getElementById('draggable-div');
    const dragonDrop = new DragonDrop(demo1, {
      handle: '.handle',
      announcement: {
        grabbed: (el) => {
          console.log('grabbed');
          return `${el.querySelector('span').innerText} grabbed`;
        },
        dropped: (el) => {
          console.log('dropped');
          return `${el.querySelector('span').innerText} dropped`;
        },
        reorder: (el, items) => {
          console.log('reordered');
          const pos = items.indexOf(el) + 1;
          const text = el.querySelector('span').innerText;
          console.log('The rankings have been updated');
          return `The rankings have been updated, ${text} is now ranked #${pos} out of ${items.length}`;
        },
        cancel: () => {
          console.log('Reranking canceled');
          return 'Reranking cancelled.';
        }
      }
    });
  }, []);

  return (
    <>
      <h2>Dragon Drop test component here</h2>
      <p id="global-help">
        Activate the reorder button and use the arrow keys to reorder the list or use your mouse to
        drag/reorder. Press escape to cancel the reordering.
        <span className="offscreen">Ensure screen reader is in focus mode.</span>
      </p>
      <div id="draggable-div" className="demo">
        {nameArr.map((name) => (
          <div style={{padding: '5px'}} key={name.id}>
            <button aria-describedby="global-help"
                    type="button"
                    className="fa fa-bars handle"
                    aria-labelledby={`name-item-${name.id}`}
                    id={`name-button-${name.id}`}>
              <div className="offscreen">Reorder</div>
            </button>
            <span id={`name-item-${name.id}`}>&nbsp;{name.name}</span>
          </div>
        ))}
      </div>
    </>
  );
}