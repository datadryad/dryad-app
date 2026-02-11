import React, {useEffect, useState, useRef} from 'react';
import axios from 'axios';
import {Field, Form, Formik} from 'formik';
import {showSavedMsg, showSavingMsg} from '../../../../lib/utils';
import Journal from './Journal';

function PublicationForm({
  current, resource, setResource, setSponsored, hidden, connections, importType,
}) {
  const formRef = useRef();
  const [msn, setMSN] = useState('');
  const [primary, setPrimary] = useState(null);
  const [prefix, setPrefix] = useState('');
  const [jTitle, setJTitle] = useState('');
  const [issn, setISSN] = useState('');

  const mapping = {
    manuscript: 'Submitted manuscript',
    published: 'Published article',
    preprint: 'Preprint',
  };

  const submitForm = (values) => {
    showSavingMsg();
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const submitVals = {
      authenticity_token,
      import_type: importType,
      publication_name: values.pub_title || null,
      resource_id: resource.id,
      publication_issn: values.pub_issn || null,
      do_import: false,
      primary_article_doi: values.primary_article_doi || null,
      msid: values.msid || null,
    };
    axios.patch(
      '/stash_datacite/publications/update',
      submitVals,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    ).then((data) => {
      if (data.status === 200) {
        const {
          journal, related_identifiers, resource_publication, resource_preprint,
        } = data.data;
        setResource((r) => ({
          ...r,
          journal,
          related_identifiers,
          resource_publication,
          resource_preprint: resource_preprint || undefined,
        }));
        setJTitle(journal?.title || jTitle);
        setISSN(journal?.issn || issn);
        showSavedMsg();
      }
    });
  };

  useEffect(() => {
    if (jTitle !== undefined) {
      if (jTitle !== resource.resource_publication?.publication_name) setSponsored(false);
    }
  }, [jTitle]);

  useEffect(() => {
    const unsetJournal = () => {
      setJTitle('');
      setISSN('');
      formRef.current.values.pub_title = '';
      formRef.current.values.pub_issn = '';
    };
    if (current && hidden) {
      const initial = JSON.stringify(formRef.current.initialValues);
      if (importType === 'manuscript') {
        formRef.current.values.msid = '';
        if (!connections.includes('published')) unsetJournal();
      } else {
        formRef.current.values.primary_article_doi = '';
        if (!connections.includes('manuscript')) unsetJournal();
      }
      if (initial !== JSON.stringify(formRef.current.values)) submitForm(formRef.current.values);
    }
  }, [current, hidden]);

  useEffect(() => {
    const [, pref] = resource?.journal?.manuscript_number_regex?.match(/\(([a-z]+[-_]*)/i) || [];
    setPrefix(pref || '');
  }, [resource?.journal?.manuscript_number_regex]);

  useEffect(() => {
    const {resource_publication: res_pub, resource_preprint: res_pre = {}} = resource;
    const {publication_name, publication_issn, manuscript_number} = importType === 'preprint' ? res_pre : res_pub;
    const primary_article = resource.related_identifiers.find((r) => r.work_type === (importType === 'preprint' ? 'preprint' : 'primary_article'));
    setMSN(manuscript_number);
    setPrimary(primary_article || null);
    setJTitle(publication_name);
    setISSN(publication_issn);
  }, [resource.resource_publication, resource.related_identifiers, resource.resource_preprint]);

  const journalInput = (id) => (
    <div className="input-stack" style={{flex: 1}}>
      <Journal
        formRef={formRef}
        title={jTitle}
        setTitle={(v) => {
          formRef.current.values.pub_title = v;
          setJTitle(v);
        }}
        issn={issn}
        setIssn={(v) => {
          formRef.current.values.pub_issn = v;
          setISSN(v);
        }}
        controlOptions={
          {
            labelText: importType === 'preprint' ? 'Preprint server' : 'Journal name',
            htmlId: `publication_${id}`,
            isRequired: true,
            errorId: `journal_${id}_error`,
            desBy: `journal_${id}-ex`,
          }
        }
      />
      <div id={`journal_${id}-ex`}><i aria-hidden="true" />{importType === 'preprint' ? 'bioRxiv, SSRN' : 'Nature, Science'}</div>
    </div>
  );

  return (
    <div hidden={hidden || null} className="callout">
      <Formik
        initialValues={
          {
            pub_title: jTitle || '',
            pub_issn: issn || '',
            primary_article_doi: primary?.related_identifier || '',
            msid: msn || '',
          }
        }
        enableReinitialize
        innerRef={formRef}
        onSubmit={(values, {setSubmitting}) => {
          submitForm(values);
          setSubmitting(false);
        }}
      >
        {(formik) => (
          <Form style={{margin: '1em auto'}}>
            {importType === 'manuscript' ? (
              <>
                <p style={{fontSize: '.98rem', marginTop: 0}}>
                Are you currently submitting your manuscript?
                Enter <code>NA</code> if you do not have a Manuscript number. This can be updated once a number is assigned by the journal.
                </p>
                <div className="input-line">
                  {journalInput('ms')}
                  <div className="input-stack" style={{flex: 1}}>
                    <label className="input-label" htmlFor="msid">
                    Manuscript number
                    </label>
                    <Field
                      className="c-input__text"
                      type="text"
                      name="msid"
                      id="msid"
                      onBlur={() => formik.handleSubmit()}
                      aria-describedby="man-ex"
                      aria-errormessage="msid_error"
                      placeholder={prefix}
                      required
                    />
                    <div id="man-ex"><i aria-hidden="true" />APPS-D-17-00113</div>
                  </div>
                </div>
              </>
            ) : (
              <div className="input-line">
                <div className="input-stack" style={{flex: 2}}>
                  <label className="input-label required" htmlFor="primary_article_doi">
                    {mapping[importType]} DOI
                  </label>
                  <Field
                    className="c-input__text"
                    type="text"
                    name="primary_article_doi"
                    id="primary_article_doi"
                    onBlur={() => formik.handleSubmit()}
                    aria-describedby="doi-ex"
                    aria-errormessage={`${importType}_doi_error`}
                    required
                  />
                  <div id="doi-ex"><i aria-hidden="true" />10.5702/qlm.1266rr</div>
                </div>
                {primary && !primary.verified && journalInput(importType)}
              </div>
            )}
          </Form>
        )}
      </Formik>
    </div>
  );
}

export default PublicationForm;
