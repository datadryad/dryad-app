import React, {useEffect, useState, useRef} from 'react';
import axios from 'axios';
import {
  Field, Form, Formik, useFormikContext,
} from 'formik';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import Journal from './Journal';

function ImportCheck({importType, journal, setDisable}) {
  const {values} = useFormikContext();

  useEffect(() => {
    if (importType === 'manuscript' && (!journal || !values.msid)) {
      setDisable(true);
    } else if (importType === 'published' && (!journal || !values.primary_article_doi)) {
      setDisable(true);
    } else if (importType === 'preprint' && (!journal || !values.primary_article_doi)) {
      setDisable(true);
    } else {
      setDisable(false);
    }
  }, [importType, values, journal]);
}

function PublicationForm({
  resource, setResource, setSponsored, importType,
}) {
  const formRef = useRef();
  const {resource_publication, resource_preprint = {}} = resource;
  const {publication_name, publication_issn, manuscript_number} = importType === 'preprint' ? resource_preprint : resource_publication;
  const primary_article = resource.related_identifiers.find((r) => r.work_type === (importType === 'preprint' ? 'preprint' : 'primary_article'));
  const [importError, setImportError] = useState('');
  const [journal, setJournal] = useState(publication_name);
  const [issn, setIssn] = useState(publication_issn);
  const [apiJournal, setAPIJournal] = useState(false);
  const [hide, setHide] = useState(false);
  const [disable, setDisable] = useState(false);
  const [loading, setLoading] = useState(false);

  const apiError = 'To import metadata, this journal requires that you start your Dryad submission from within their manuscript system.';

  useEffect(() => {
    setSponsored(false);
  }, [journal]);

  useEffect(() => {
    setHide(importType === 'manuscript' && apiJournal);
    setImportError(importType === 'manuscript' && apiJournal ? apiError : '');
  }, [importType, apiJournal]);

  const submitForm = (values) => {
    showSavingMsg();
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {
      authenticity_token,
      import_type: importType,
      publication_name: journal,
      resource_id: resource.id,
      publication_issn: issn,
      do_import: values.isImport,
      primary_article_doi: values.primary_article_doi || null,
      msid: values.msid || null,
    };
    if (values.isImport) setLoading(true);
    axios.patch(
      '/stash_datacite/publications/update',
      submitVals,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status === 200) {
        const res_pub = {
          publication_name: journal || null,
          publication_issn: issn || null,
          manuscript_number: values.msid || null,
        };
        const {
          error, journal: j, related_identifiers, import_data,
        } = data.data;
        if (import_data) {
          const {
            title, authors, descriptions, subjects, contributors,
          } = import_data;
          setResource((r) => ({
            ...r,
            title,
            authors,
            subjects,
            contributors,
            descriptions,
            journal: j,
            ...(importType === 'preprint' ? {
              resource_preprint: res_pub,
            } : {
              resource_publication: res_pub,
            }),
            related_identifiers,
          }));
        } else {
          setResource((r) => ({
            ...r,
            journal: j,
            ...(importType === 'preprint' ? {
              resource_preprint: res_pub,
            } : {
              resource_publication: res_pub,
            }),
            related_identifiers,
          }));
        }

        setImportError(error || ((importType === 'manuscript' && apiJournal) && apiError) || '');
        showSavedMsg();
        setLoading(false);
      }
    });
  };

  return (
    <Formik
      initialValues={
        {
          primary_article_doi: primary_article?.related_identifier || '',
          msid: manuscript_number || '',
          isImport: false,
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values);
        setSubmitting(false);
      }}
    >
      {(formik) => (
        <Form style={{margin: '1em auto'}}>
          <ImportCheck importType={importType} journal={journal} setDisable={setDisable} />
          <Field name="isImport" type="hidden" />
          <div className="callout alt">
            <p><i className="fas fa-file-import" /> Enter your publication information to import the title and other metadata</p>
          </div>
          <div className="input-line">
            <div className="input-stack">
              <Journal
                formRef={formRef}
                title={journal}
                setTitle={setJournal}
                issn={issn}
                setIssn={setIssn}
                setAPIJournal={setAPIJournal}
                controlOptions={
                  {
                    labelText: importType === 'preprint' ? 'Preprint server' : 'Journal name',
                    htmlId: 'publication',
                    isRequired: true,
                    errorId: 'journal_error',
                    desBy: 'journal-ex',
                  }
                }
              />
              <div id="journal-ex"><i aria-hidden="true" />{importType === 'preprint' ? 'bioRxiv, SSRN' : 'Nature, Science'}</div>
            </div>
            {importType !== 'manuscript' && (
              <div className="input-stack">
                <label className="input-label required" htmlFor="primary_article_doi">
                  DOI
                </label>
                <Field
                  className="c-input__text"
                  type="text"
                  name="primary_article_doi"
                  id="primary_article_doi"
                  onBlur={() => { // defaults to formik.handleBlur
                    formRef.current.values.isImport = false;
                    formik.handleSubmit();
                  }}
                  aria-describedby="doi-ex"
                  aria-errormessage="doi_error"
                  required
                />
                <div id="doi-ex"><i aria-hidden="true" />10.5702/qlm.1266rr</div>
              </div>
            )}
            {importType === 'manuscript' && (
              <div className="input-stack">
                <label className="input-label" htmlFor="msid">
                  Manuscript number
                </label>
                <Field
                  className="c-input__text"
                  type="text"
                  name="msid"
                  id="msid"
                  onBlur={() => { // defaults to formik.handleBlur
                    formRef.current.values.isImport = false;
                    formik.handleSubmit();
                  }}
                  aria-describedby="man-ex"
                  aria-errormessage="msid_error"
                  required
                />
                <div id="man-ex"><i aria-hidden="true" />APPS-D-17-00113</div>
              </div>
            )}
            <div className="input-stack">
              <span style={{height: '23px'}} />
              {resource.title ? (
                <button
                  type="button"
                  name="commit"
                  className="o-button__plain-text5"
                  hidden={hide}
                  disabled={disable}
                  aria-controls="overwrite-dialog"
                  onClick={() => document.getElementById('overwrite-dialog').showModal()}
                >
                  <i className="fas fa-file-import" />{' '}
                  Overwrite metadata
                </button>
              ) : (
                <button
                  type="button"
                  name="commit"
                  className="o-button__plain-text5"
                  hidden={hide}
                  disabled={disable}
                  onClick={() => {
                    formRef.current.values.isImport = true;
                    formik.handleSubmit();
                  }}
                >
                  <i className="fas fa-file-import" />{' '}
                  Import metadata
                </button>
              )}
            </div>
          </div>
          <p id="population-warnings" className="o-metadata__autopopulate-message">
            {importError}
          </p>
          {loading && <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>}
          <dialog
            id="overwrite-dialog"
            className="modalDialog"
            role="alertdialog"
            aria-labelledby="import-alert-title"
            aria-describedby="import-alert-desc"
            aria-modal="true"
          >
            <div className="modalClose">
              <button aria-label="Close" type="button" onClick={() => document.getElementById('overwrite-dialog').close()} />
            </div>
            <div>
              <h1 id="import-alert-title">Overwrite inserted metadata?</h1>
              <p id="import-alert-desc">
                Your {importType === 'published' ? 'published article' : importType} information has been saved.
                Are you certain you also want to attempt to overwrite your submission title and any other metadata?
              </p>
              <div className="c-modal__buttons-right">
                <button
                  type="button"
                  className="o-button__plain-text2"
                  onClick={() => {
                    document.getElementById('overwrite-dialog').close();
                    formRef.current.values.isImport = true;
                    formik.handleSubmit();
                  }}
                >Import new metadata
                </button>
                <button type="button" className="o-button__plain-text7" onClick={() => document.getElementById('overwrite-dialog').close()}>
                  Cancel
                </button>
              </div>
            </div>
          </dialog>
        </Form>
      )}
    </Formik>
  );
}

export default PublicationForm;
