import React, {
  Fragment, useRef, useState, useEffect,
} from 'react';
import {upCase} from '../../lib/utils';
import ChecklistNav, {Checklist} from '../components/Checklist';
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

export default function Submission({
  submission, ownerId, admin, s3_dir_name, config_s3, config_frictionless, config_cedar, change_tenant,
}) {
  const subRef = useRef();
  const [resource, setResource] = useState(JSON.parse(submission));
  const [step, setStep] = useState({name: 'Start'});
  const [open, setOpen] = useState(false);
  const [review, setReview] = useState(!!resource.identifier.process_date.submitted || !!resource.accepted_agreement);
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const steps = [
    {
      name: 'Title/Import',
      pass: !!resource.title,
      fail: publicationCheck(resource),
      component: <Publication resource={resource} setResource={setResource} />,
      help: <PublicationHelp />,
      preview: <PubPreview resource={resource} admin={admin} />,
    },
    {
      name: 'Authors',
      pass: !!resource.title && resource.authors.length > 0,
      fail: !!resource.title && authorCheck(resource.authors, ownerId),
      component: <Authors resource={resource} setResource={setResource} admin={admin} ownerId={ownerId} />,
      help: <AuthHelp />,
      preview: <AuthPreview resource={resource} admin={admin} />,
    },
    {
      name: 'Support',
      pass: resource.contributors.find((c) => c.contributor_type === 'funder'),
      fail: fundingCheck(resource.contributors.filter((f) => f.contributor_type === 'funder')),
      component: <Support resource={resource} setResource={setResource} />,
      help: <SuppHelp />,
      preview: <SuppPreview resource={resource} admin={admin} />,
    },
    {
      name: 'Subjects',
      pass: keywordPass(resource.subjects),
      fail: keywordFail(resource.subjects),
      component: <Subjects resource={resource} setResource={setResource} />,
      help: <SubjHelp />,
      preview: <SubjPreview resource={resource} />,
    },
    {
      name: 'Description',
      pass: resource.descriptions.some((d) => !!d.description),
      fail: abstractCheck(resource),
      component: <Description resource={resource} setResource={setResource} admin={admin} cedar={config_cedar} />,
      help: <DescHelp />,
      preview: <DescPreview resource={resource} />,
    },
    {
      name: 'Files',
      pass: resource.generic_files.length > 0,
      fail: ((review && resource.generic_files.length < 1) && <p className="error-text">Files are required</p>) || filesCheck(resource.generic_files),
      component: <UploadFiles
        resource={resource}
        setResource={setResource}
        s3_dir_name={s3_dir_name}
        config_s3={config_s3}
        config_frictionless={config_frictionless}
      />,
      help: <FilesHelp />,
      preview: <FilesPreview resource={resource} />,
    },
    {
      name: 'README',
      pass: resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description,
      fail: readmeCheck(resource),
      component: <ReadMeWizard
        dcsDescription={resource.descriptions.find((d) => d.description_type === 'technicalinfo')}
        resource={resource}
        setResource={setResource}
        // errors={readmeCheck(resource)}
      />,
      help: <ReadMeHelp />,
      preview: <ReadMePreview resource={resource} />,
    },
    {
      name: 'Related works',
      pass: resource.related_identifiers.some((rid) => !!rid.related_identifier) || resource.accepted_agreement,
      fail: worksCheck(resource),
      component: <RelatedWorks resource={resource} setResource={setResource} />,
      help: <WorksHelp setTitleStep={() => setStep(steps[steps.findIndex((l) => l.name === 'Title/Import')])} />,
      preview: <WorksPreview resource={resource} admin={admin} />,
    },
    {
      name: 'Agreements',
      pass: resource.accepted_agreement,
      fail: ((review && !resource.accepted_agreement) && <p className="error-text" id="agree_err">Terms must be accepted</p>) || false,
      component: <Agreements resource={resource} setResource={setResource} form={change_tenant} />,
      help: <AgreeHelp />,
      preview: <Agreements resource={resource} preview />,
    },
  ];

  useEffect(() => {
    const main = document.getElementById('maincontent');
    if (review && step.name === 'Start') {
      main.classList.add('submission-review');
    } else if (review) {
      main.classList.remove('submission-review');
    }
  }, [review, step]);

  useEffect(() => {
    if (!review) {
      if (steps.find((c) => c.fail) || steps.findLast((c) => c.pass)) {
        const stop = steps.findLastIndex((c) => c.pass) + 1 > steps.length - 1;
        setStep(steps.find((c) => c.fail) || stop ? steps.findLast((c) => c.pass) : steps[steps.findLastIndex((c) => c.pass) + 1]);
        setOpen('start');
      }
    }
    if (subRef.current) {
      const observer = new MutationObserver(() => {
        const et = document.querySelector('.error-text');
        const old = document.querySelector('*[aria-invalid]');
        if (old) old.removeAttribute('aria-invalid');
        if (et) {
          const ind = et.dataset.index;
          const inv = ind
            ? document.querySelectorAll(`*[aria-errormessage="${et.id}"]`)[ind]
            : document.querySelector(`*[aria-errormessage="${et.id}"]`);
          if (inv) {
            inv.setAttribute('aria-invalid', true);
          }
        }
      });
      observer.observe(subRef.current, {subtree: true, childList: true});
    }
  }, []);

  if (review) {
    if (step.name !== 'Start') {
      return (
        <>
          <h1>{upCase(resource.resource_type.resource_type)} submission preview editor</h1>
          <div className="submission-edit">
            <div id="submission-nav" className="open">
              <div style={{textAlign: 'right', fontSize: '1.3rem'}}>
                <button type="button" className="checklist-link" onClick={() => setStep({name: 'Start'})}>
                  <span className="checklist-icon">
                    <i className="fas fa-chevron-left" aria-hidden="true" />
                  </span>Back to preview
                </button>
              </div>
            </div>
            <div id="submission-wizard" className="open">
              <div>
                <div ref={subRef}>
                  {step.component}
                  {step.name === 'Start' && (
                    <p>Complete the checklist, and submit your data for publication.</p>
                  )}
                  {!['Start', 'README'].includes(step.name) && (
                    steps.find((s) => s.name === step.name).fail
                  )}
                </div>
                <div id="submission-help">
                  <div className="o-dataset-nav">
                    <button
                      type="button"
                      className="o-button__plain-text2"
                      onClick={() => setStep({name: 'Start'})}
                    >
                      Preview changes
                    </button>
                    <div className="saving_text" hidden>Saving&hellip;</div>
                    <div className="saved_text" hidden>All progress saved</div>
                  </div>
                  <div>
                    {step.help}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </>
      );
    }
    return (
      <>
        <h1>{upCase(resource.resource_type.resource_type)} submission preview</h1>
        <Checklist steps={steps} step={{}} setStep={setStep} open />
        <div id="submission-wizard">
          {steps.map((s) => (
            <section key={s.name} aria-label={s.name}>
              {s.preview}
              {s.fail}
            </section>
          ))}
        </div>
        <div id="submission-submit">
          {steps.some((s) => s.fail) ? (
            <div className="callout err">
              <p>Fix the errors above in order to complete your submission</p>
            </div>
          ) : (
            <p>Ready to complete your submission?</p>
          )}
          <form action="/stash_datacite/resources/submission" method="post">
            {!steps.some((s) => s.fail) && (
              <>
                <input type="hidden" name="authenticity_token" value={authenticity_token} />
                <input type="hidden" name="resource_id" value={resource.id} />
                <input type="hidden" name="software_license" value={resource.identifier?.software_license?.identifier || 'MIT'} />
              </>
            )}
            <button type="submit" className="o-button__plain-text1" disabled={steps.some((s) => s.fail)}>
              Submit for {resource.hold_for_peer_review ? 'peer review' : 'curation and publication'}
            </button>
          </form>
        </div>
      </>
    );
  }

  return (
    <div className="submission-edit">
      <ChecklistNav steps={steps} step={step} setStep={setStep} open={open} setOpen={setOpen} />
      <div id="submission-wizard" className={(step.name === 'Start' && 'start') || (open && 'open') || ''}>
        <div>
          <div ref={subRef}>
            <div style={{display: 'flex', alignItems: 'baseline', justifyContent: 'space-between'}}>
              <h1>{upCase(resource.resource_type.resource_type)} submission</h1>
              <div className="saving_text" hidden>Saving&hellip;</div>
              <div className="saved_text" hidden>All progress saved</div>
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
                    setReview(true);
                  }}
                >
                  Preview submission
                </button>
              ) : (
                <button
                  type="button"
                  className="o-button__plain-text2"
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
