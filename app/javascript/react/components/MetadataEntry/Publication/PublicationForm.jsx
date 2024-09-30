import React, {useState, useRef} from 'react';
import axios from 'axios';
import {Field, Form, Formik} from 'formik';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import Journal from './Journal';

function PublicationForm({resource, setResource, importType}) {
  const formRef = useRef();
  const {identifier, resource_publication} = resource;
  const {publication_name, publication_issn, manuscript_number} = resource_publication;
  const primary_article = resource.related_identifiers.find((r) => r.work_type === 'primary_article');
  const [importError, setImportError] = useState('');
  const [journal, setJournal] = useState(publication_name);
  const [issn, setIssn] = useState(publication_issn);
  const [hideImport, setHideImport] = useState(false);

  const hideImportButton = () => {
    if (importType === 'manuscript') {
      if (!journal) return true;
      if (hideImport) return true;
    }
    return false;
  };

  const disableImportButton = () => {
    if (importType === 'manuscript') {
      if (!formRef?.current?.values.msid) return true;
    } else if (importType === 'published') {
      if (!journal) return true;
      if (!formRef?.current?.values.primary_article_doi) return true;
    }
    return false;
  };

  const submitForm = (values) => {
    showSavingMsg();
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    setResource((r) => {
      r.resource_publication = {
        publication_name: journal,
        publication_issn: issn,
        manuscript_number: values.msid || null,
      };
      const {related_identifiers} = r;
      r.related_identifiers = [
        {work_type: 'primary_article', doi: values.primary_article_doi || null},
        ...related_identifiers,
      ];
      return r;
    });
    const submitVals = {
      authenticity_token,
      import_type: importType,
      publication_name: journal,
      identifier_id: identifier.id,
      resource_id: resource.id,
      publication_issn: issn,
      do_import: values.isImport,
      primary_article_doi: values.primary_article_doi || null,
      msid: values.msid || null,
    };

    axios.patch(
      '/stash_datacite/publications/update',
      submitVals,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      console.log(data);
      if (data.status !== 200) {
        console.log('Response failure from publication information save/import');
      }
      setImportError(data.data.error || '');
      showSavedMsg();

      if (data.data.reloadPage) {
        setImportError('Reloading imported data...');
        window.location.reload(true);
      }
    });
  };

  return (
    <Formik
      initialValues={
        {
          primary_article_doi: primary_article?.doi || '',
          msid: manuscript_number || '',
          isImport: false,
        }
      }
      innerRef={formRef}
      onSubmit={(values, {setSubmitting}) => {
        submitForm(values).then(() => { setSubmitting(false); });
      }}
    >
      {(formik) => (
        <Form style={{margin: '1em auto'}}>
          <Field name="isImport" type="hidden" />
          <div className="input-line">
            <div className="input-stack">
              <Journal
                formRef={formRef}
                title={journal}
                setTitle={setJournal}
                issn={issn}
                setIssn={setIssn}
                setHideImport={setHideImport}
                controlOptions={
                  {
                    htmlId: 'publication',
                    labelText: 'Journal name',
                    isRequired: true,
                  }
                }
              />
            </div>
            {importType !== 'manuscript' && (
              <div className="input-stack">
                <label className="c-input__label required" htmlFor="primary_article_doi">
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
                />
              </div>
            )}
            {importType !== 'published' && (
              <div className="input-stack">
                <label className="c-input__label required" htmlFor="msid">
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
                />
              </div>
            )}
            <button
              type="button"
              name="commit"
              className="o-button__plain-text2"
              hidden={hideImportButton()}
              disabled={disableImportButton()}
              onClick={() => {
                formRef.current.values.isImport = true;
                formik.handleSubmit();
              }}
            >
              Import metadata
            </button>
          </div>
          <div id="population-warnings" className="o-metadata__autopopulate-message">
            {importError}
          </div>
        </Form>
      )}
    </Formik>
  );
}

export default PublicationForm;
