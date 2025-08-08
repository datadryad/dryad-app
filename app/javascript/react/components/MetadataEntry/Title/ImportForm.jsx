import React, {useEffect, useState} from 'react';
import axios from 'axios';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';

function ImportForm({
  resource, setResource, importType, setImportError, apiJournals,
}) {
  const [primary_article_doi, setDOI] = useState(null);
  const [apiJournal, setAPIJournal] = useState(false);
  const [hide, setHide] = useState(false);
  const [disable, setDisable] = useState(false);
  const [overwrite, setOverwrite] = useState(false);
  const [loading, setLoading] = useState(false);

  const apiError = 'To import metadata, this journal requires that you start your Dryad submission from within their manuscript system.';

  useEffect(() => {
    setHide(importType === 'manuscript' && apiJournal);
    setImportError(importType === 'manuscript' && apiJournal ? apiError : '');
  }, [importType, apiJournal]);

  useEffect(() => {
    if (importType === 'manuscript' && (!resource.resource_publication?.publication_name || !resource.resource_publication?.manuscript_number)) {
      setDisable(true);
    } else if (importType === 'published' && !primary_article_doi) {
      setDisable(true);
    } else if (importType === 'preprint' && !primary_article_doi) {
      setDisable(true);
    } else {
      setDisable(false);
    }
  }, [importType, resource.resource_publication, primary_article_doi]);

  useEffect(() => {
    setOverwrite(resource.title || resource.authors.length > 1 || resource.subjects.length);
  }, [resource]);

  useEffect(() => {
    setDOI(resource.related_identifiers.find((r) => r.work_type === (importType === 'preprint' ? 'preprint' : 'primary_article'))?.related_identifier
      || null);
    setAPIJournal(apiJournals.includes(resource.resource_publication?.publication_issn));
  }, [resource, apiJournals]);

  const submit = () => {
    showSavingMsg();
    setLoading(true);
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {
      authenticity_token,
      import_type: importType,
      resource_id: resource.id,
      publication_name: importType === 'preprint' ? resource.resource_preprint?.publication_name : resource.resource_publication?.publication_name,
      publication_issn: importType === 'preprint' ? resource.resource_preprint?.publication_issn : resource.resource_publication?.publication_issn,
      do_import: true,
      primary_article_doi,
      msid: importType !== 'preprint' ? resource.resource_publication?.manuscript_number || null : null,
    };
    axios.patch(
      '/stash_datacite/publications/update',
      submitVals,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status === 200) {
        const {error, import_data} = data.data;
        if (import_data) {
          const {
            title, authors, descriptions, subjects, contributors,
          } = import_data;
          setResource((r) => ({
            ...r,
            identifier: {...r.identifier, import_info: importType},
            title,
            authors,
            subjects,
            contributors,
            descriptions,
          }));
        }
        setImportError(error || ((importType === 'manuscript' && apiJournal) && apiError) || '');
        showSavedMsg();
        setLoading(false);
      }
    });
  };

  return (
    <>
      <div style={{display: 'flex', alignItems: 'baseline', gap: '1.5ch'}}>
        <p>
          {importType === 'preprint' ? resource.resource_preprint?.publication_name : resource.resource_publication?.publication_name}{' '}
          {importType === 'published' ? 'article' : importType}{' '}
          <code>{importType === 'manuscript' ? resource.resource_publication?.manuscript_number : primary_article_doi}</code>
        </p>
        <button
          type="button"
          name="commit"
          className="o-button__plain-text5"
          style={{whiteSpace: 'nowrap'}}
          hidden={hide}
          disabled={disable}
          aria-controls="overwrite-dialog"
          onClick={() => {
            if (!loading) {
              if (overwrite) {
                document.getElementById(`overwrite-dialog${importType}`).showModal();
              } else {
                submit();
              }
            }
          }}
        >
          {loading ? <i className="fas fa-circle-notch fa-spin" role="img" aria-label="Loading..." />
            : <i className="fas fa-file-import" aria-hidden="true" />}{' '}
          {overwrite ? 'Overwrite' : 'Import'} metadata
        </button>
      </div>
      <dialog
        id={`overwrite-dialog${importType}`}
        className="modalDialog"
        role="alertdialog"
        aria-labelledby="import-alert-title"
        aria-describedby="import-alert-desc"
        aria-modal="true"
      >
        <div className="modalClose">
          <button aria-label="Close" type="button" onClick={() => document.getElementById(`overwrite-dialog${importType}`).close()} />
        </div>
        <div>
          <h1 id="import-alert-title">Overwrite inserted metadata?</h1>
          <p id="import-alert-desc">
            Are you certain you want to attempt to overwrite your submission title and any other metadata?
          </p>
          <div className="c-modal__buttons-right">
            <button
              type="button"
              className="o-button__plain-text2"
              onClick={() => {
                document.getElementById(`overwrite-dialog${importType}`).close();
                submit();
              }}
            >Import new metadata
            </button>
            <button type="button" className="o-button__plain-text7" onClick={() => document.getElementById(`overwrite-dialog${importType}`).close()}>
              Cancel
            </button>
          </div>
        </div>
      </dialog>
    </>
  );
}

export default ImportForm;
