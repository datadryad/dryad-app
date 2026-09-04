import React, {useState, useRef, useEffect} from 'react';
import axios from 'axios';
import {isEqual} from 'lodash';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import Authors from './Authors'
import Affiliations from './Affiliations'
import Contributions from './Contributions'

export default function AuthorSteps({resource, setResource, current, user, error}) {
  const errRef = useRef(null);
  const [errNum, setErrNum] = useState(null);
  const [authors, setAuthors] = useState(resource.authors);
  const [users, setUsers] = useState(resource.users)
  const [step, setStep] = useState(1);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

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

  const secTitles = ['Author list', 'Affiliations', 'Contributions']

  const sections = {
    1: <Authors {...{authors, setAuthors, user, users, setUsers, updateItem}} resource_id={resource.id} />,
    2: <Affiliations {...{authors, updateItem}} />,
    3: <Contributions {...{authors, updateItem}} />,
  }

  useEffect(() => {
    if (!isEqual(resource.authors, authors) || !isEqual(resource.users, users)) {
      setResource((r) => ({...r, authors, users}));
    }
  }, [authors, users]);

  useEffect(() => {
    const buttons = document.getElementById('author-steps').children
    Array.from(buttons).forEach(li => {
      const b = li.querySelector('button')
      b.classList.remove('error-step')
      b.removeAttribute('aria-describedby')
    })
    if (errNum !== null && errNum !== step - 1) {
      const button = buttons[errNum].querySelector('button')
      button.setAttribute('aria-describedby', errRef.current)
      button.classList.add('error-step')
    }
  }, [errNum, step])

  useEffect(() => {
    if (error && errRef.current !== error.props.id) {
      if (error.props.id === 'author_aff_error') setErrNum(1)
      else if (error.props.id === 'author_role_error') setErrNum(2)
      else setErrNum(0)
      errRef.current = error.props.id;
    }
    if (!error) {
      setErrNum(null)
    }
  }, [error])

  useEffect(() => {
    if (current && error) {
      if (error.props.id === 'author_aff_error') setStep(2)
      if (error.props.id === 'author_role_error') setStep(3)
    }
  }, [current]);
  
  return (
    <>
      <ol className="steps-wrapper" id="author-steps">
        {Object.keys(sections).map((i) => (
          /* eslint-disable eqeqeq */
          <li
            key={`step${i}`}
            className={`step${i < step ? ' completed' : ''}${i == step ? ' current' : ''}`}
            aria-current={step == i ? 'step' : null}
          >
            <button
              aria-controls="author-sections"
              onClick={() => setStep(Number(i))}
              onKeyDown={(e) => {
                if (['Enter', 'Space'].includes(e.key)) {
                  setStep(Number(i));
                }
              }}
            >
              <span className="bar" /><span className="step-counter">{i}</span><span className="step-name">{secTitles[i - 1]}</span>
            </button>
          </li>
        ))}
      </ol>
      <div id="author-sections">
        <h3>{secTitles[step -1]}</h3>
        {sections[step]}
        <div role="alert">
          <div className="screen-reader-only">
            {error && errNum ? `There is an error in the ${secTitles[errNum]} step: ` : null}
          </div>
          {error}
        </div>
        <div className="dataset-nav" style={{marginTop: '2rem', marginBottom: '2rem'}}>
          {step === secTitles.length ? <span/> : (
            <button
              type="button"
              className="o-button__plain-text1"
              onClick={() => setStep((s) => Number(s) + 1)}
              id="authors-next"
              aria-labelledby="submission-step-title authors-next"
            >
              Next <i className="fa fa-caret-right" aria-hidden="true" />
            </button>
          )}
          {step > 1 && (
            <button
              type="button"
              className="o-button__plain-text0"
              onClick={() => setStep((s) => Number(s) - 1)}
              id="authors-previous"
              aria-labelledby="submission-step-title authors-previous"
            >
              <i className="fa fa-caret-left" aria-hidden="true" /> Previous
            </button>
          )}
        </div>
      </div>
    </>
  );
}