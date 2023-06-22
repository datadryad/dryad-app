import React, {useState, useRef, useEffect} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import DragonDrop from 'drag-on-drop';
import FunderForm from './FunderForm';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function Funders({
  resourceId, contributors, icon, createPath, updatePath, deletePath, groupings,
}) {
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const [funders, setFunders] = useState(contributors);
  const [disabled, setDisabled] = useState(contributors[0]?.name_identifier_id === '0');

  const dragonRef = useRef(null);
  const oldOrderRef = useRef(null);
  const [dragonDrop, setDragonDrop] = useState(null);

  const savedWrapper = useRef();

  const toOrderObj = (orderArr) => orderArr.reduce((obj, item) => {
    obj[item.id] = item.funder_order;
    return obj;
  }, {});

  // function relies on css class dd-list-item and data-id items in the dom for info, so render should make those
  function updateOrderFromDom(localFunders) {
    oldOrderRef.current = funders.map((item) => ({id: item.id, funder_order: item.funder_order}));
    const items = Array.from(dragonRef.current.querySelectorAll('li.dd-list-item'));

    const newOrder = items.map((item, idx) => ({id: parseInt(item.getAttribute('data-id'), 10), funder_order: idx}));

    // make into key/values with object id as key and order as value for fast lookup

    const contributor = toOrderObj(newOrder);

    showSavingMsg();
    // update order in the database
    axios.patch(
      '/stash_datacite/contributors/reorder',
      {contributor, authenticity_token},
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

    // duplicate funders list with updated order values reflecting new order
    const newFunders = localFunders.map((item) => ({...item, funder_order: contributor[item.id]}));

    // replace
    setFunders(newFunders);
  }

  const wrappingFunction = () => {
    updateOrderFromDom(funders);
  };

  const lastOrder = () => (funders.length ? Math.max(...funders.map((contrib) => contrib.funder_order)) + 1 : 0);

  const addNewFunder = () => {
    console.log(`${(new Date()).toISOString()}: Adding funder`);
    const contributor = {
      contributor_name: '',
      contributor_type: 'funder',
      identifier_type: 'crossref_funder_id',
      name_identifier_id: '',
      resource_id: resourceId,
      funder_order: lastOrder(),
    };
    const contribJson = {authenticity_token, contributor};

    axios.post(createPath, contribJson, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't add new funder from remote server");
        }
        setFunders((prevState) => [...prevState, data.data]);
      });
  };

  // delete a funder from the list
  const removeItem = (id) => {
    console.log(`${(new Date()).toISOString()}: deleting funder`);
    const trueDelPath = deletePath.replace('id_xox', id);
    showSavingMsg();

    // requiring the resource like this is weird in a controller for a model that isn't a resource, but it's how it is set up
    if (id && !`${id}`.startsWith('new')) {
      const submitVals = {
        authenticity_token,
        contributor: {
          id,
          resource_id: resourceId,
        },
      };
      axios.delete(trueDelPath, {
        data: submitVals,
        headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'},
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
    setFunders((prevState) => prevState.filter((item) => (item.id !== id)));
  };

  // update the funder in the list from old to new values
  const updateFunder = (updatedContributor) => {
    // replace item in the funder list if it has changed
    setFunders((prevState) => prevState.map((funder) => (updatedContributor.id === funder.id ? updatedContributor : funder)));
  };

  const setNoFunders = async (e) => {
    const noFunders = e.currentTarget.checked;
    const [contributor] = funders;
    setDisabled(noFunders);
    contributor.contributor_name = noFunders ? 'N/A' : '';
    contributor.name_identifier_id = noFunders ? '0' : '';
    // submit by json
    return axios.patch(
      updatePath,
      {authenticity_token, contributor},
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
      // forces data update in the collection containing me
      updateFunder(contributor);
    });
  };

  if (!dragonDrop && funders.length < 1) addNewFunder();

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
          const contributor = toOrderObj(oldOrderRef.current);

          axios.patch(
            '/stash_datacite/contributors/reorder',
            {contributor, authenticity_token},
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

          // duplicate funders list with updated order values reflecting new (old) order
          // const newAuth = localAuthors.map((item) => ({...item, funder_order: newOrderObj[item.id]}));

          setFunders((prevState) => prevState.map((item) => ({...item, funder_order: contributor[item.id]})));
        }, 1000);
      });

      setDragonDrop(dragon);

      // dragon.on('dropped', function (container, item) {updateOrderFromDom(dragonRef.current); });
    } else {
      console.log('reinitializing dragon drop with funder updates');
      if (funders.length < 1) addNewFunder();
      savedWrapper.current = wrappingFunction;
      dragonDrop.initElements(dragonRef.current);
    }
  }, [funders]);

  return (
    <section style={{marginBottom: '20px'}}>
      <p id="funders-global-help" className="offscreen">
        Activate the reorder button and use the arrow keys to reorder the list or use your mouse to
        drag/reorder. Press escape to cancel the reordering.
        <span>Ensure screen reader is in focus mode.</span>
      </p>
      {!disabled && (
        <>
          <ul className="dragon-drop-list" aria-labelledby="funders-head" ref={dragonRef}>
            {funders
              .slice(0)
              .sort((a, b) => {
              // sorts by id if order not present and gets around 0 being falsey in javascript
                if (a.funder_order === undefined || a.funder_order === null || b.funder_order === undefined || b.funder_order === null) {
                  return a.id - b.id;
                }
                return a.funder_order - b.funder_order;
              })
              .map((contrib) => (
                <li key={contrib.id} className="dd-list-item" data-id={contrib.id}>
                  <button
                    aria-describedby="funders-global-help"
                    type="button"
                    className="fa-workaround handle c-input"
                    aria-label="Drag to reorder this funder"
                    id={`funder-button-${contrib.id}`}
                    style={{background: `url('${icon}') no-repeat`, boxShadow: 'none'}}
                  >
                    <div className="offscreen">Reorder</div>
                  </button>
                  <FunderForm
                    key={contrib.id}
                    resourceId={resourceId}
                    contributor={contrib}
                    groupings={groupings}
                    disabled={disabled}
                    updatePath={updatePath}
                    removeFunction={removeItem}
                    updateFunder={updateFunder}
                  />
                </li>
              ))}
          </ul>
          <button
            className="t-describe__add-funder-button o-button__add"
            type="button"
            disabled={disabled}
            onClick={addNewFunder}
            style={{marginRight: '2em'}}
          >
          Add another funder
          </button>
        </>
      )}
      <label><input type="checkbox" checked={disabled} onChange={setNoFunders} /> No funding received</label>
    </section>
  );
}

export default Funders;

// resourceId, contributors, icon, createPath, updatePath, deletePath

Funders.propTypes = {
  resourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  contributors: PropTypes.array.isRequired,
  icon: PropTypes.string.isRequired,
  createPath: PropTypes.string.isRequired,
  updatePath: PropTypes.string.isRequired,
  deletePath: PropTypes.string.isRequired,
};
