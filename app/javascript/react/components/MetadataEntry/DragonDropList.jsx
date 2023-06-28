import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import DragonDrop from 'drag-on-drop';
import './Dragon.css';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export const orderedItems = ({items, typeName}) => items.slice(0).sort((a, b) => {
  const orderProp = `${typeName}_order`;
  // sorts by id if order not present and gets around 0 being falsey in javascript
  if (a[orderProp] === undefined || a[orderProp] === null || b[orderProp] === undefined || b[orderProp] === null) {
    return a.id - b.id;
  }
  return a[orderProp] - b[orderProp];
});

export function DragonListItem({item, typeName, children}) {
  return (
    <li key={item.id} className="dd-list-item" data-id={item.id}>
      <button
        aria-describedby={`${typeName}s-global-help`}
        type="button"
        className="fa-workaround handle c-input"
        aria-label={`Drag to reorder this ${typeName}`}
        id={`${typeName}-button-${item.id}`}
        style={{background: 'url(\'/images/fa-barfs.svg\') no-repeat', boxShadow: 'none'}}
      >
        <div className="offscreen">Reorder</div>
      </button>
      {children}
    </li>
  );
}

export default function DragonDropList({
  model, typeName, items, path, setItems, children, ...props
}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const dragonRef = useRef(null);
  const oldOrderRef = useRef(null);
  const [dragonDrop, setDragonDrop] = useState(null);

  /* need to set a ref so it doesn't reset to initial values and also keep updating this wrapping function that is used in the
   callback from the other library every time the items change. the savedWrapper.current = wrappingFunction below.

   This is especially annoying and has to do with closures maintaining old state from initial load and mismatch between
   react and standard javascript code.

   See https://overreacted.io/making-setinterval-declarative-with-react-hooks/ or
   https://stackoverflow.com/questions/57847594/react-hooks-accessing-up-to-date-state-from-within-a-callback
   It will make your head hurt.
  */

  const savedWrapper = useRef();

  const orderProp = `${typeName}_order`;

  const toOrderObj = (orderArr) => orderArr.reduce((obj, item) => {
    obj[item.id] = item[orderProp];
    return obj;
  }, {});

  // function relies on css class dd-list-item and data-id items in the dom for info, so render should make those
  function updateOrderFromDom(localItems) {
    oldOrderRef.current = localItems.map((item) => ({id: item.id, [orderProp]: item[orderProp]}));
    const currItems = Array.from(dragonRef.current.querySelectorAll('li.dd-list-item'));
    const newOrder = currItems.map((item, idx) => ({id: parseInt(item.getAttribute('data-id'), 10), [orderProp]: idx}));

    // make into key/values with object id as key and order as value for fast lookup
    const newOrderObj = toOrderObj(newOrder);

    showSavingMsg();
    // update order in the database
    axios.patch(
      path,
      {[model]: newOrderObj, authenticity_token},
      {
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Accept: 'application/json',
        },
      },
    ).then((data) => {
      if (data.status !== 200) {
        console.log(`Response failure not a 200 response from ${typeName}s save`);
      }
      showSavedMsg();
    });

    // duplicate list with updated order values reflecting new order
    const newItems = localItems.map((item) => ({...item, [orderProp]: newOrderObj[item.id]}));
    // replace
    setItems(newItems);
  }

  const wrappingFunction = () => {
    updateOrderFromDom(items);
  };

  // to set up dragon drop or reinit on changes
  useEffect(() => {
    if (!dragonDrop) {
      console.log(`initializing ${typeName} DragonDrop for first time`);
      // the "announcement section below is to announce changes to screen readers
      const dragon = new DragonDrop(dragonRef.current, {
        handle: '.handle',
        announcement: {
          grabbed: (el) => `${el.querySelector('input').value} grabbed`,
          dropped: (el) => `${el.querySelector('input').value} dropped`,
          reorder: (el, x) => {
            const pos = x.indexOf(el) + 1;
            const text = el.querySelector('input').value;
            return `The rankings have been updated, ${text} is now ranked #${pos} out of ${x.length}`;
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
            path,
            {[model]: newOrderObj, authenticity_token},
            {
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                Accept: 'application/json',
              },
            },
          ).then((data) => {
            if (data.status !== 200) {
              console.log(`Response failure not a 200 response from ${typeName}s reversion save for canceling drag and drop`);
            }
          });

          // duplicate items list with updated order values reflecting new (old) order
          // const newAuth = localAuthors.map((item) => ({...item, [type]_order: newOrderObj[item.id]}));

          setItems((prevState) => prevState.map((item) => ({...item, [orderProp]: newOrderObj[item.id]})));
        }, 1000);
      });

      setDragonDrop(dragon);

      // dragon.on('dropped', function (container, item) {updateOrderFromDom(dragonRef.current); });
    } else {
      console.log(`reinitializing dragon drop with ${typeName} updates`);
      savedWrapper.current = wrappingFunction;
      dragonDrop.initElements(dragonRef.current);
    }
  }, [items]);
  return (
    <section {...props}>
      <p id={`${typeName}s-global-help`} className="offscreen">
        Activate the reorder button and use the arrow keys to reorder the list or use your mouse to
        drag/reorder. Press escape to cancel the reordering.
        <span>Ensure screen reader is in focus mode.</span>
      </p>
      <ul className="dragon-drop-list" aria-labelledby={`${typeName}s-head`} ref={dragonRef}>
        {children}
      </ul>
    </section>
  );
}
