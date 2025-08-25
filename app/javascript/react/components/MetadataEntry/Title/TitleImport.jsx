import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {sentenceCase} from '../../../../lib/sentence-case';
import ImportForm from './ImportForm';
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

export default function TitleImport({current, resource, setResource}) {
  const [connections, setConnections] = useState([]);
  const [apiJournals, setAPIJournals] = useState([]);
  const [importError, setImportError] = useState(null);
  const [caseWarning, setCaseWarning] = useState(false);
  const [dupeWarning, setDupeWarning] = useState(false);
  const [caseTitle, setCaseTitle] = useState(null);

  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  useEffect(() => {
    if (resource.title) {
      const p = document.createElement('p');
      p.innerHTML = resource.title;
      const testTitle = p.textContent || p.innerText;
      setCaseTitle(testTitle);
      if (!resource.identifier.process_date?.processing) {
        axios.get(`/resources/${resource.id}/dupe_check.json`).then((data) => {
          setDupeWarning(data.data?.[0]?.title || false);
        });
      } else {
        setDupeWarning(false);
      }
      if (capitals(testTitle)) {
        setCaseWarning(true);
      } else {
        setCaseWarning(false);
      }
    }
  }, [resource.title]);

  useEffect(() => {
    async function getList() {
      axios.get('/stash_datacite/publications/api_list').then((data) => {
        setAPIJournals(data.data.api_journals);
      });
    }
    if (current && !apiJournals.length) getList();
  }, [current, apiJournals]);

  useEffect(() => {
    if (current) {
      const selected = [];
      const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article')?.related_identifier;
      const preprint = resource.resource_preprint?.publication_name
        && resource.related_identifiers.find((r) => r.work_type === 'preprint')?.related_identifier;
      if (resource.resource_publication.manuscript_number) selected.push('manuscript');
      if (primary_article) selected.push('published');
      if (preprint) selected.push('preprint');
      setConnections(selected);
    }
  }, [current]);

  return (
    <>
      {!!connections.length && (
        <div className="callout alt">
          <p>
            <i className="fas fa-file-import" />{' '}
            The title and other metadata can sometimes be imported. Choose a source and click the button to import
          </p>
        </div>
      )}

      {connections.map((type) => (
        <ImportForm
          current={current}
          resource={resource}
          setResource={setResource}
          setImportError={setImportError}
          apiJournals={apiJournals}
          importType={type}
          key={type}
        />
      ))}

      {!!connections.length && (
        <div className="callout alt">
          <p><i className="fas fa-info-circle" /> Type in or import your dataset title</p>
        </div>
      )}
      <p id="population-warnings" role="status" className="o-metadata__autopopulate-message">
        {importError}
      </p>
      <Title resource={resource} setResource={setResource} />

      {caseWarning && (
        <div className="callout warn">
          <p style={{fontSize: '.98rem'}}>Please correct your dataset title to sentence case, which could look like:</p>
          <p><span>{sentenceCase(caseTitle)}</span>
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
