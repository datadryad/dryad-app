import React, {useEffect, useState, useRef} from 'react';
import axios from 'axios';
import {
  Field, Form, Formik, useFormikContext,
} from 'formik';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import Journal from './Journal';

function ImportCheck({importType, jTitle, setDisable}) {
  const {values} = useFormikContext();

  useEffect(() => {
    if (importType === 'manuscript' && (!jTitle || !values.msid)) {
      setDisable(true);
    } else if (importType === 'published' && (!jTitle || !values.primary_article_doi)) {
      setDisable(true);
    } else if (importType === 'preprint' && (!jTitle || !values.primary_article_doi)) {
      setDisable(true);
    } else {
      setDisable(false);
    }
  }, [importType, values, jTitle]);
}

function PublicationForm({
  current, resource, setResource, setSponsored, importType,
}) {
  const formRef = useRef();
  const {resource_publication: res_pub, resource_preprint: res_pre = {}} = resource;
  const {publication_name, publication_issn, manuscript_number} = importType === 'preprint' ? res_pre : res_pub;
  const primary_article = resource.related_identifiers.find((r) => r.work_type === (importType === 'preprint' ? 'preprint' : 'primary_article'));
  const [importError, setImportError] = useState('');
  const [prefix, setPrefix] = useState('');
  const [jTitle, setJTitle] = useState(publication_name);
  const [issn, setISSN] = useState(publication_issn);
  const [apiJournal, setAPIJournal] = useState(false);
  const [hide, setHide] = useState(false);
  const [disable, setDisable] = useState(false);
  const [loading, setLoading] = useState(false);

  const apiError = 'To import metadata, this journal requires that you start your Dryad submission from within their manuscript system.';

  useEffect(() => {
    if (jTitle !== publication_name) setSponsored(false);
  }, [jTitle]);

  useEffect(() => {
    setHide(importType === 'manuscript' && apiJournal);
    setImportError(importType === 'manuscript' && apiJournal ? apiError : '');
  }, [importType, apiJournal]);

  useEffect(() => {
    const [, pref] = resource?.journal?.manuscript_number_regex?.match(/\(([a-z]+[-_]*)/i) || [];
    setPrefix(pref || '');
  }, [resource?.journal?.manuscript_number_regex]);

  const submitForm = (values) => {
    showSavingMsg();
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {
      authenticity_token,
      import_type: importType,
      publication_name: jTitle,
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
        const {
          error, journal, related_identifiers, resource_publication, import_data,
        } = data.data;
        if (import_data) {
          const {
            title, authors, descriptions, subjects, contributors, resource_preprint,
          } = import_data;
          setResource((r) => ({
            ...r,
            identifier: {...r.identifier, import_info: importType},
            title,
            authors,
            subjects,
            contributors,
            descriptions,
            journal,
            resource_preprint,
            resource_publication,
            related_identifiers,
          }));
          const {publication_name: jtitle, publication_issn: jissn} = importType === 'preprint' ? resource_preprint : resource_publication;
          setJTitle(jtitle);
          setISSN(jissn);
        } else {
          setResource((r) => ({
            ...r,
            journal,
            related_identifiers,
            resource_publication,
          }));
          setJTitle(journal?.title || jTitle);
          setISSN(journal?.issn || issn);
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
          <ImportCheck importType={importType} jTitle={jTitle} setDisable={setDisable} />
          <Field name="isImport" type="hidden" />
          {importType === 'manuscript' && (
            <p style={{fontSize: '.98rem'}}>
              Are you currently submitting your manuscript?
              Enter <code>NA</code> as the Manuscript number. This can be updated once a number is assigned by the journal.
            </p>
          )}
          <div className="input-line">
            <div className="input-stack">
              <Journal
                current={current}
                formRef={formRef}
                title={jTitle}
                setTitle={setJTitle}
                issn={issn}
                setIssn={setISSN}
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
              <div className="input-stack" style={{flex: 2}}>
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
                  placeholder={prefix}
                  required
                />
                <div id="man-ex"><i aria-hidden="true" />APPS-D-17-00113</div>
              </div>
            )}
            <div className="input-stack">
              <span style={{height: '23px'}} />
              <button
                type="button"
                name="commit"
                className="o-button__plain-text5"
                hidden={hide}
                disabled={disable}
                aria-controls="overwrite-dialog"
                onClick={() => {
                  if (resource.title) {
                    document.getElementById('overwrite-dialog').showModal();
                  } else {
                    formRef.current.values.isImport = true;
                    formik.handleSubmit();
                  }
                }}
              >
                {loading ? <i className="fas fa-circle-notch fa-spin" role="img" aria-label="Loading..." />
                  : <i className="fas fa-file-import" aria-hidden="true" />}{' '}
                {resource.title ? 'Overwrite' : 'Import'} metadata
              </button>
            </div>
          </div>
          <p id="population-warnings" className="o-metadata__autopopulate-message">
            {importError}
          </p>
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
