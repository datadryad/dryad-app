import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {sentenceCase} from '../../../../lib/sentence-case';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import PublicationForm from './PublicationForm';
import Title from './Title';

const copyTitle = (e) => {
  const copyButton = e.currentTarget.firstElementChild;
  const title = e.currentTarget.previousSibling.textContent;
  navigator.clipboard.writeText(title).then(() => {
    // Successful copy
    copyButton.parentElement.setAttribute('title', 'Title copied');
    copyButton.classList.remove('fa-paste');
    copyButton.classList.add('fa-check');
    copyButton.innerHTML = '<span class="screen-reader-only">Title copied</span>';
    setTimeout(() => {
      copyButton.parentElement.setAttribute('title', 'Copy title');
      copyButton.classList.add('fa-paste');
      copyButton.classList.remove('fa-check');
      copyButton.innerHTML = '';
    }, 2000);
  });
};

const capitals = (t) => {
  if (t === t.toUpperCase()) return true;
  const [l] = t.match(/\p{Letter}/u);
  if (t.match(/\b[\p{Lu}].*?\b/ug)?.length > t.split(/\s/).length * 0.6 || l !== l.toUpperCase()) {
    return t !== sentenceCase(t);
  }
  return false;
};

export default function Publication({current, resource, setResource}) {
  const subType = resource.resource_type.resource_type;
  const [assoc, setAssoc] = useState(null);
  const [showTitle, setShowTitle] = useState(false);
  const [connections, setConnections] = useState([]);
  const [sponsored, setSponsored] = useState(false);
  const [caseWarning, setCaseWarning] = useState(false);
  const [dupeWarning, setDupeWarning] = useState(false);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const optionChange = (choice) => {
    showSavingMsg();
    setResource((r) => ({...r, identifier: {...r.identifier, import_info: choice}}));
    axios.patch(
      `/resources/${resource.id}/import_type`,
      {authenticity_token, import_info: choice},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't change import_type on remote server");
        }
        showSavedMsg();
      });
  };

  const setImport = (e) => {
    const v = e.target.value;
    if (v === 'no') {
      setAssoc(false);
      setConnections([]);
      optionChange('other');
    }
    if (v === 'yes') setAssoc(true);
  };

  const setOption = (e) => {
    const checked = e.currentTarget.querySelectorAll('input:checked');
    const selected = [...checked].map((i) => i.value);
    setConnections(selected);
    optionChange(selected[0]);
  };

  useEffect(() => {
    if (assoc === false) setShowTitle(true);
    if (assoc === true && !resource.title) setShowTitle(false);
  }, [assoc]);

  useEffect(() => {
    const {publication_name, manuscript_number} = resource.resource_publication;
    const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
    const {publication_name: preprint_server} = resource.resource_preprint || {};
    const preprint = resource.related_identifiers.find((r) => r.work_type === 'preprint')?.related_identifier;
    if ((!!publication_name && (!!manuscript_number || !!primary_article))
      || (!!preprint_server && !!preprint)) {
      setShowTitle(true);
    }
    setSponsored(!!resource.journal?.payment_plan_type && (manuscript_number || primary_article) ? resource.journal.title : false);
    if (resource.title) {
      if (!resource.identifier.process_date?.processing) {
        axios.get(`/resources/${resource.id}/dupe_check.json`).then((data) => {
          setDupeWarning(data.data?.[0]?.title || false);
        });
      } else {
        setDupeWarning(false);
      }
      if (capitals(resource.title)) {
        setCaseWarning(true);
      } else {
        setCaseWarning(false);
      }
    }
  }, [resource.journal, resource.resource_publication, resource.title, resource.related_identifiers]);

  useEffect(() => {
    const selected = [];
    const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
    const preprint = resource.related_identifiers.find((r) => r.work_type === 'preprint')?.related_identifier;
    if (resource.resource_publication.manuscript_number) selected.push('manuscript');
    if (primary_article) selected.push('published');
    if (preprint) selected.push('preprint');
    setConnections(selected);
    if (!!selected.length) setAssoc(true);
  }, []);

  return (
    <>
      <div className="callout alt">
        <p><i className="fas fa-circle-info" /> If your data is connected to a journal, the Data Publishing Charge may be sponsored</p>
      </div>
      <fieldset onChange={setImport}>
        <legend>
          Is your {subType} associated with a preprint, an article, or a manuscript submitted to a journal?
        </legend>
        <p className="radio_choice">
          <label><input name="assoc" type="radio" value="yes" defaultChecked={assoc === true ? 'checked' : null} />Yes</label>
          <label><input name="assoc" type="radio" value="no" required defaultChecked={assoc === false ? 'checked' : null} />No</label>
        </p>
      </fieldset>

      {assoc && (
        <fieldset onChange={setOption} style={{margin: '2rem 0'}}>
          <legend>
              Which would you like to connect?
          </legend>
          <ul className="o-list" style={{marginTop: '1rem'}}>
            <li className="radio_choice">
              <label>
                <input name="import" type="checkbox" value="manuscript" defaultChecked={connections.includes('manuscript') ? 'checked' : null} />
                  Submitted manuscript
              </label>
            </li>
            <li className="radio_choice">
              <label>
                <input name="import" type="checkbox" value="published" defaultChecked={connections.includes('published') ? 'checked' : null} />
                  Published article
              </label>
            </li>
            <li className="radio_choice">
              <label>
                <input name="import" type="checkbox" value="preprint" defaultChecked={connections.includes('preprint') ? 'checked' : null} />
                  Preprint
              </label>
            </li>
          </ul>
        </fieldset>
      )}

      {sponsored && (
        <div className="callout">
          <p>Payment for this submission is sponsored by <b>{sponsored}</b></p>
        </div>
      )}

      {!!connections.length && (
        <div className="callout alt">
          <p>
            <i className="fas fa-file-import" />{' '}
            The title and other metadata can sometimes be imported. Choose a source and click the button to import
          </p>
        </div>
      )}

      {connections.map((type) => (
        <PublicationForm
          current={current}
          connections={connections}
          resource={resource}
          setResource={setResource}
          setSponsored={setSponsored}
          importType={type}
          key={type}
        />
      ))}

      {showTitle && (
        <>
          {!!connections.length && (
            <div className="callout alt">
              <p><i className="fas fa-info-circle" /> Type in or import your dataset title</p>
            </div>
          )}
          <Title resource={resource} setResource={setResource} />
        </>
      )}

      {caseWarning && (
        <div className="callout warn">
          <p style={{fontSize: '.98rem'}}>Please correct your dataset title to sentence case, which could look like:</p>
          <p><span>{sentenceCase(resource.title)}</span>
            <span
              className="copy-icon"
              role="button"
              tabIndex="0"
              aria-label="Copy title"
              title="Copy title"
              onClick={copyTitle}
              onKeyDown={(e) => {
                if (e.key === ' ' || e.key === 'Enter') {
                  copyTitle(e);
                }
              }}
            ><i className="fa fa-paste" role="status" />
            </span>
          </p>
        </div>
      )}

      {dupeWarning && (
        <div className="callout warn">
          <p>
            This is the same title or primary publication as your existing submission:
            <b style={{display: 'block', marginTop: '.5ch'}}>{dupeWarning}</b>
          </p>
          <div>
            <form action={`/resources/${resource.id}`} method="post" style={{display: 'inline'}}>
              <input type="hidden" name="_method" value="delete" />
              <input type="hidden" name="authenticity_token" value={authenticity_token} />
              <button type="submit" className="o-link__primary" style={{border: 0, padding: 0, background: 'transparent'}}>
                Delete this new submission
              </button>
            </form> if you did not intend to create it.
          </div>
          <p>
            Do you need to split a dataset into multiple submissions?
            Please ensure the title of this submission distinguishes it, or marks it as part of a series.
          </p>
        </div>
      )}
    </>
  );
}
