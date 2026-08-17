import React, {useState, useRef, useEffect, useCallback} from 'react';
import axios from 'axios';
import {isEqual, debounce} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import Authors from './Authors'
import Affiliations from './Affiliations'
import Contributions from './Contributions'

export default function AuthorSteps({resource, setResource, current, user, error}) {
  const errRef = useRef(null);
  const [active, setActive] = useState(false);
  const [authors, setAuthors] = useState(resource.authors);
  const [users, setUsers] = useState(resource.users)
  const [step, setStep] = useState(1);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const inactive = useCallback(debounce(() => setActive(false), 2000), []);

  const activity = () => {
    setActive(true);
    inactive();
  }

  const updateItem = (author) => {
    showSavingMsg();
    activity();
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

  const secTitles = ['Authors', 'Affiliations', 'Contributions']

  const sections = {
    1: <Authors {...{authors, setAuthors, user, users, setUsers, updateItem}} resource_id={resource.id} />,
    2: <Affiliations {...{authors, updateItem}} />,
    3: <Contributions {...{authors, updateItem}} />,
  }

  useEffect(() => {
    if (errRef.current !== error.props.id && !active) {
      if (error.props.id === 'author_aff_error') setStep(2)
      if (error.props.id === 'author_role_error') setStep(3)
      errRef.current = error.props.id;
    }
  }, [active, error])

  useEffect(() => {
    if (!isEqual(resource.authors, authors) || !isEqual(resource.users, users)) {
      setResource((r) => ({...r, authors, users}));
    }
  }, [authors, users]);

  useEffect(() => {
    if (current) {
      setAuthors(resource.authors);
      setUsers(resource.users);
      document.body.addEventListener('click', activity)
      document.body.addEventListener('keypress', activity)
    }
    () => {
      document.body.removeEventListener('click', activity)
      document.body.removeEventListener('keypress', activity)
    }
  }, [current]);
  
  return (
    <>
      <div className="steps-wrapper">
        {Object.keys(sections).map((i) => (
          /* eslint-disable eqeqeq */
          <div
            key={`step${i}`}
            className={`step${i < step ? ' completed' : ''}${i == step ? ' current' : ''}`}
            aria-current={step == i ? 'step' : null}
            role="button"
            tabIndex={0}
            onClick={() => setStep(Number(i))}
            onKeyDown={(e) => {
              if (['Enter', 'Space'].includes(e.key)) {
                setStep(Number(i));
              }
            }}
          >
            <span className="bar" /><span className="step-counter">{i}</span><span className="step-name">{secTitles[i - 1]}</span>
          </div>
        ))}
      </div>
      <h3>{secTitles[step -1]}</h3>
      {sections[step]}
      <div role="alert">{error}</div>
      <div className="dataset-nav" style={{marginTop: '2rem', marginBottom: '2rem'}}>
        {step === secTitles.length ? <span/> : (
          <button
            type="button"
            className="o-button__plain-text1"
            onClick={() => setStep((s) => Number(s) + 1)}
            id="readme-next"
            aria-labelledby="submission-step-title readme-next"
          >
            Next <i className="fa fa-caret-right" aria-hidden="true" />
          </button>
        )}
        {step > 1 && (
          <button
            type="button"
            className="o-button__plain-text0"
            onClick={() => setStep((s) => Number(s) - 1)}
            id="readme-previous"
            aria-labelledby="submission-step-title readme-previous"
          >
            <i className="fa fa-caret-left" aria-hidden="true" /> Previous
          </button>
        )}
      </div>
    </>
  );
}