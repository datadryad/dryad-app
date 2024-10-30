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
    } else {
      setDisable(false);
    }
  }, [importType, values, journal]);
}

function PublicationForm({
  resource, setResource, setSponsored, importType,
}) {
  const formRef = useRef();
  const {resource_publication} = resource;
  const {publication_name, publication_issn, manuscript_number} = resource_publication;
  const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article');
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
            resource_publication: res_pub,
            related_identifiers,
          }));
        } else if (error || apiJournal || !journal) {
          setResource((r) => ({
            ...r,
            journal: j,
            resource_publication: res_pub,
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
          <p style={{marginTop: '2em'}}>Enter your publication information and import the title and other metadata:</p>
          <div className="input-line">
            <div className="input-stack" style={{flex: 0}}>
              <Journal
                formRef={formRef}
                title={journal}
                setTitle={setJournal}
                issn={issn}
                setIssn={setIssn}
                setAPIJournal={setAPIJournal}
                controlOptions={
                  {
                    htmlId: 'publication',
                    labelText: 'Journal name',
                    isRequired: true,
                    errorId: 'journal_error',
                  }
                }
              />
            </div>
            {importType !== 'manuscript' && (
              <div className="input-stack">
                <label className="input-label required" htmlFor="primary_article_doi">
                  DOI
                </label>
                <Field
                  className="c-input__text"
                  placeholder="10.5702/qlm.1266rr"
                  type="text"
                  name="primary_article_doi"
                  id="primary_article_doi"
                  onBlur={() => { // defaults to formik.handleBlur
                    formRef.current.values.isImport = false;
                    formik.handleSubmit();
                  }}
                  aria-errormessage="doi_error"
                  required
                />
              </div>
            )}
            {importType !== 'published' && (
              <div className="input-stack">
                <label className="input-label" htmlFor="msid">
                  Manuscript number
                </label>
                <Field
                  className="c-input__text"
                  placeholder="APPS-D-17-00113"
                  type="text"
                  name="msid"
                  id="msid"
                  onBlur={() => { // defaults to formik.handleBlur
                    formRef.current.values.isImport = false;
                    formik.handleSubmit();
                  }}
                  aria-errormessage="msid_error"
                  required
                />
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
                onClick={() => {
                  formRef.current.values.isImport = true;
                  formik.handleSubmit();
                }}
              >
                Import metadata
              </button>
            </div>
          </div>
          <div id="population-warnings" className="o-metadata__autopopulate-message">
            {importError}
          </div>
          {loading && <p><i className="fa fa fa-spinner fa-spin" aria-hidden="true" /><span className="screen-reader-only">Loading...</span></p>}
        </Form>
      )}
    </Formik>
  );
}

export default PublicationForm;
