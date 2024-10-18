import React, {
  Fragment, useRef, useState, useEffect,
} from 'react';
import {upCase} from '../../lib/utils';
import ChecklistNav, {Checklist} from '../components/Checklist';
import SubmissionForm from '../components/SubmissionForm';
import Publication, {PubPreview, publicationCheck} from '../components/MetadataEntry/Publication';
import Authors, {AuthPreview, authorCheck} from '../components/MetadataEntry/Authors';
import Support, {SuppPreview, fundingCheck} from '../components/MetadataEntry/Support';
import Subjects, {SubjPreview, keywordPass, keywordFail} from '../components/MetadataEntry/Subjects';
import Description, {DescPreview, abstractCheck} from '../components/MetadataEntry/Description';
import RelatedWorks, {WorksPreview, worksCheck} from '../components/MetadataEntry/RelatedWorks';
import UploadFiles, {FilesPreview, filesCheck} from '../components/UploadFiles';
import ReadMeWizard, {ReadMePreview, readmeCheck} from '../components/ReadMeWizard';
import Agreements from '../components/MetadataEntry/Agreements';
import SubmissionHelp, {
  PublicationHelp, AuthHelp, SuppHelp, SubjHelp, DescHelp, FilesHelp, ReadMeHelp, WorksHelp, AgreeHelp,
} from '../components/SubmissionHelp';
/* eslint-disable jsx-a11y/no-autofocus */

export default function Submission({
  submission, ownerId, admin, s3_dir_name, config_s3, config_frictionless, config_cedar, change_tenant,
}) {
  const subRef = useRef(null);
  const previewRef = useRef(null);
  const [resource, setResource] = useState(JSON.parse(submission));
  const [step, setStep] = useState({name: 'Start'});
  const [open, setOpen] = useState(false);
  const [review, setReview] = useState(!!resource.identifier.process_date.processing || !!resource.accepted_agreement);
  const previous = resource.previous_curated_resource;
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const steps = [
    {
      name: 'Title/Import',
      pass: !!resource.title,
      fail: publicationCheck(resource, review),
      component: <Publication resource={resource} setResource={setResource} />,
      help: <PublicationHelp />,
      preview: <PubPreview resource={resource} previous={previous} admin={admin} />,
    },
    {
      name: 'Authors',
      pass: !!resource.title && resource.authors.length > 0,
      fail: (review || !!resource.title) && authorCheck(resource.authors, ownerId),
      component: <Authors resource={resource} setResource={setResource} admin={admin} ownerId={ownerId} />,
      help: <AuthHelp />,
      preview: <AuthPreview resource={resource} previous={previous} admin={admin} />,
    },
    {
      name: 'Support',
      pass: resource.contributors.find((c) => c.contributor_type === 'funder'),
      fail: fundingCheck(resource.contributors.filter((f) => f.contributor_type === 'funder')),
      component: <Support resource={resource} setResource={setResource} />,
      help: <SuppHelp type={resource.resource_type.resource_type} />,
      preview: <SuppPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Subjects',
      pass: keywordPass(resource.subjects),
      fail: keywordFail(resource.subjects, review),
      component: <Subjects resource={resource} setResource={setResource} />,
      help: <SubjHelp />,
      preview: <SubjPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Description',
      pass: resource.descriptions.some((d) => !!d.description),
      fail: abstractCheck(resource, review),
      component: <Description resource={resource} setResource={setResource} admin={admin} cedar={config_cedar} />,
      help: <DescHelp type={resource.resource_type.resource_type} />,
      preview: <DescPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Files',
      pass: resource.generic_files.length > 0,
      fail: filesCheck(resource.generic_files, review),
      component: <UploadFiles
        resource={resource}
        setResource={setResource}
        s3_dir_name={s3_dir_name}
        config_s3={config_s3}
        config_frictionless={config_frictionless}
      />,
      help: <FilesHelp />,
      preview: <FilesPreview resource={resource} previous={previous} />,
    },
    {
      name: 'README',
      pass: resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description,
      fail: readmeCheck(resource, review),
      component: <ReadMeWizard
        dcsDescription={resource.descriptions.find((d) => d.description_type === 'technicalinfo')}
        resource={resource}
        setResource={setResource}
        // errors={readmeCheck(resource)}
      />,
      help: <ReadMeHelp />,
      preview: <ReadMePreview resource={resource} previous={previous} admin={admin} />,
    },
    {
      name: 'Related works',
      pass: resource.related_identifiers.some((ri) => !!ri.related_identifier && ri.work_type !== 'primary_article') || resource.accepted_agreement,
      fail: worksCheck(resource, review),
      component: <RelatedWorks resource={resource} setResource={setResource} />,
      help: <WorksHelp setTitleStep={() => setStep(steps[steps.findIndex((l) => l.name === 'Title/Import')])} />,
      preview: <WorksPreview resource={resource} previous={previous} admin={admin} />,
    },
    {
      name: 'Agreements',
      pass: resource.accepted_agreement,
      fail: ((review && !resource.accepted_agreement) && <p className="error-text" id="agree_err">Terms must be accepted</p>) || false,
      component: <Agreements resource={resource} setResource={setResource} form={change_tenant} />,
      help: <AgreeHelp type={resource.resource_type.resource_type} />,
      preview: <Agreements resource={resource} previous={previous} preview />,
    },
  ];

  if (resource.resource_type.resource_type === 'collection') {
    steps.splice(5, 2);
  }

  const markInvalid = () => {
    const et = document.querySelector('.error-text');
    if (et) {
      const ind = et.dataset.index;
      const inv = ind
        ? document.querySelectorAll(`*[aria-errormessage="${et.id}"]`)[ind]
        : document.querySelector(`*[aria-errormessage="${et.id}"]`);
      if (inv) {
        inv.setAttribute('aria-invalid', true);
      }
    }
  };

  useEffect(() => {
    const main = document.getElementById('maincontent');
    if (review && step.name === 'Start') {
      main.classList.add('submission-review');
    } else if (review) {
      main.classList.remove('submission-review');
    }
  }, [review, step]);

  useEffect(() => {
    if (subRef.current) {
      markInvalid();
      const observer = new MutationObserver(() => {
        const old = document.querySelector('*[aria-invalid]');
        if (old) old.removeAttribute('aria-invalid');
        markInvalid();
      });
      observer.observe(subRef.current, {subtree: true, childList: true});
    }
  }, [subRef.current]);

  useEffect(() => {
    if (!review) {
      if (steps.find((c) => c.fail) || steps.findLast((c) => c.pass)) {
        if (steps.find((c) => c.fail)) {
          setStep(steps.find((c) => c.fail));
        } else {
          const stop = (steps.findLastIndex((c) => c.pass) + 1) > (steps.length - 1);
          setStep(stop ? steps.findLast((c) => c.pass) : steps[steps.findLastIndex((c) => c.pass) + 1]);
        }
        setOpen('start');
      }
    } else if (resource.identifier.publication_date) {
      document.querySelector('#submission-checklist li:last-child button').setAttribute('disabled', true);
    }
  }, []);

  if (review) {
    return (
      <>
        <h1>{upCase(resource.resource_type.resource_type)} submission preview{step.name !== 'Start' ? ' editor' : ''}</h1>
        <nav aria-label="Submission editing" className={step.name !== 'Start' ? 'screen-reader-only' : null}>
          <Checklist steps={steps} step={{}} setStep={setStep} open />
        </nav>
        {step.name === 'Start' && (
          <>
            <div id="submission-preview" ref={previewRef} className={admin ? 'track-changes' : null}>
              {steps.map((s) => (
                <section key={s.name} aria-label={s.name}>
                  {s.preview}
                  {s.fail}
                </section>
              ))}
            </div>
            <SubmissionForm steps={steps} resource={resource} previewRef={previewRef} authenticityToken={authenticity_token} admin={admin} />
          </>
        )}
        <dialog id="submission-step" open={step.name !== 'Start' || null}>
          {step.name !== 'Start' && (
            <div className="submission-edit">
              <nav id="submission-nav" className="open" aria-label="Back">
                <div style={{textAlign: 'right', fontSize: '1.3rem'}}>
                  <button
                    type="button"
                    className="checklist-link"
                    autoFocus
                    aria-controls="submission-step"
                    aria-expanded="true"
                    onClick={() => setStep({name: 'Start'})}
                  >
                    <span className="checklist-icon">
                      <i className="fas fa-chevron-left" aria-hidden="true" />
                    </span>Back to preview
                  </button>
                </div>
              </nav>
              <div id="submission-wizard" className="open">
                <div ref={subRef}>
                  <div>
                    {step.component}
                    {steps.find((s) => s.name === step.name).fail}
                  </div>
                  <div id="submission-help">
                    <div>
                      <button
                        type="button"
                        className="o-button__plain-text2"
                        onClick={() => setStep({name: 'Start'})}
                      >
                        Preview changes
                      </button>
                      <div role="status">
                        <div className="saving_text" hidden>Saving&hellip;</div>
                        <div className="saved_text" hidden>All progress saved</div>
                      </div>
                    </div>
                    <div id="submission-help-text">
                      {step.help}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </dialog>
      </>
    );
  }

  return (
    <div className="submission-edit">
      <ChecklistNav steps={steps} step={step} setStep={setStep} open={open} setOpen={setOpen} />
      <div id="submission-wizard" className={(step.name === 'Start' && 'start') || (open && 'open') || ''}>
        <div id="submission-step" role="region" aria-label={step.name} aria-live="polite">
          <div ref={subRef}>
            <div id="submission-header">
              <h1>{upCase(resource.resource_type.resource_type)} submission</h1>
              <div role="status">
                <div className="saving_text" hidden>Saving&hellip;</div>
                <div className="saved_text" hidden>All progress saved</div>
              </div>
            </div>
            {step.name === 'Start' && (<SubmissionHelp type={resource.resource_type.resource_type} />)}
            {step.component}
            {!['Start', 'README'].includes(step.name) && (
              steps.find((s) => s.name === step.name).pass && steps.find((s) => s.name === step.name).fail
            )}
          </div>
          <div id="submission-help">
            <div className="o-dataset-nav">
              {step.name === 'Agreements' ? (
                <button
                  type="button"
                  className="o-button__plain-text2"
                  disabled={!resource.accepted_agreement}
                  onClick={() => {
                    if (open === 'start') setOpen(false);
                    setStep({name: 'Start'});
                    setReview(true);
                  }}
                >
                  Preview submission
                </button>
              ) : (
                <button
                  type="button"
                  className="o-button__plain-text2"
                  aria-controls="submission-step"
                  onClick={() => {
                    setStep(steps[steps.findIndex((l) => l.name === step.name) + 1]);
                    if (open === 'start') setOpen(false);
                  }}
                >
                  Next <i className="fa fa-caret-right" aria-hidden="true" />
                </button>
              )}
              {step.name !== 'Start' && (
                <button
                  type="button"
                  className="o-button__plain-text"
                  aria-controls="submission-step"
                  onClick={() => {
                    setStep(steps[steps.findIndex((l) => l.name === step.name) - 1] || {name: 'Start'});
                    if (open === 'start') setOpen(false);
                  }}
                >
                  <i className="fa fa-caret-left" aria-hidden="true" /> Previous
                </button>
              )}
            </div>
            <div id="submission-help-text">
              {step.name === 'Start' && (
                <p>Questions? Check this spot for helpful information about each step!</p>
              )}
              {step.help}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
