import React, {
  Fragment, useRef, useState, useEffect,
} from 'react';
import {BrowserRouter, useLocation} from 'react-router-dom';
import {upCase} from '../../lib/utils';
import ChecklistNav, {Checklist} from '../components/Checklist';
import SubmissionForm from '../components/SubmissionForm';
import Publication, {PubPreview, publicationPass, publicationFail} from '../components/MetadataEntry/Publication';
import Authors, {AuthPreview, authorCheck} from '../components/MetadataEntry/Authors';
import Validation, {ValPreview, validationCheck} from '../components/MetadataEntry/Validation';
import Description, {DescPreview, abstractCheck} from '../components/MetadataEntry/Description';
import Subjects, {SubjPreview, keywordPass, keywordFail} from '../components/MetadataEntry/Subjects';
import Support, {SuppPreview, fundingCheck} from '../components/MetadataEntry/Support';
import RelatedWorks, {WorksPreview, worksCheck} from '../components/MetadataEntry/RelatedWorks';
import UploadFiles, {FilesPreview, filesCheck} from '../components/UploadFiles';
import ReadMeWizard, {ReadMePreview, readmeCheck} from '../components/ReadMeWizard';
import Agreements from '../components/MetadataEntry/Agreements';
import SubmissionHelp, {
  PublicationHelp, AuthHelp, DescHelp, SubjHelp, SuppHelp, ValHelp, FilesHelp, ReadMeHelp, WorksHelp, AgreeHelp,
} from '../components/SubmissionHelp';
/* eslint-disable jsx-a11y/no-autofocus */

function Submission({
  submission, user, s3_dir_name, config_s3, config_maximums, config_payments, config_cedar, change_tenant,
}) {
  const location = useLocation();
  const subRef = useRef(null);
  const previewRef = useRef(null);
  const [resource, setResource] = useState(JSON.parse(submission));
  const [step, setStep] = useState({name: 'Create a submission'});
  const [open, setOpen] = useState(window.innerWidth > 600);
  const [review, setReview] = useState(!!resource.identifier.process_date.processing || !!resource.accepted_agreement);
  const previous = resource.previous_curated_resource;
  const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const steps = [
    {
      name: 'Title',
      index: 0,
      pass: publicationPass(resource),
      fail: (review || publicationPass(resource)) && publicationFail(resource),
      component: <Publication resource={resource} setResource={setResource} maxSize={config_maximums.merritt_size} />,
      help: <PublicationHelp />,
      preview: <PubPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Authors',
      index: 1,
      pass: resource.authors.length > 0 && !authorCheck(resource),
      fail: (review || step.index > 0) && authorCheck(resource),
      component: <Authors resource={resource} setResource={setResource} user={user} />,
      help: <AuthHelp />,
      preview: <AuthPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Description',
      index: 2,
      pass: !abstractCheck(resource),
      fail: (review || step.index > 1) && abstractCheck(resource),
      component: <Description resource={resource} setResource={setResource} curator={user.curator} cedar={config_cedar} />,
      help: <DescHelp type={resource.resource_type.resource_type} />,
      preview: <DescPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Subjects',
      index: 3,
      pass: keywordPass(resource.subjects),
      fail: (review || step.index > 2) && keywordFail(resource.subjects),
      component: <Subjects resource={resource} setResource={setResource} />,
      help: <SubjHelp />,
      preview: <SubjPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Support',
      index: 4,
      pass: resource.contributors.find((c) => c.contributor_type === 'funder'),
      fail: fundingCheck(resource.contributors.filter((f) => f.contributor_type === 'funder')),
      component: <Support resource={resource} setResource={setResource} />,
      help: <SuppHelp type={resource.resource_type.resource_type} />,
      preview: <SuppPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Validation',
      index: 5,
      pass: !validationCheck(resource),
      fail: (review || step.index > 4) && validationCheck(resource),
      component: <Validation resource={resource} setResource={setResource} />,
      help: <ValHelp />,
      preview: <ValPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Files',
      index: 6,
      pass: resource.generic_files.length > 0,
      fail: (review || step.index > 5) && filesCheck(resource.generic_files, user.superuser, config_maximums),
      component: <UploadFiles
        resource={resource}
        setResource={setResource}
        previous={previous}
        s3_dir_name={s3_dir_name}
        config_s3={config_s3}
        config_maximums={config_maximums}
        config_payments={config_payments}
      />,
      help: <FilesHelp />,
      preview: <FilesPreview resource={resource} previous={previous} curator={user.curator} maxSize={config_maximums.files} />,
    },
    {
      name: 'README',
      index: 7,
      pass: resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description,
      fail: (review || step.index > 6) && readmeCheck(resource),
      component: <ReadMeWizard
        dcsDescription={resource.descriptions.find((d) => d.description_type === 'technicalinfo')}
        resource={resource}
        setResource={setResource}
        // errors={readmeCheck(resource)}
      />,
      help: <ReadMeHelp />,
      preview: <ReadMePreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Related works',
      index: 8,
      pass: resource.related_identifiers.some((ri) => !!ri.related_identifier && ri.work_type !== 'primary_article') || resource.accepted_agreement,
      fail: worksCheck(resource, (review || step.index > 7)),
      component: <RelatedWorks resource={resource} setResource={setResource} />,
      help: <WorksHelp setTitleStep={() => setStep(steps.find((l) => l.name === 'Title'))} />,
      preview: <WorksPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Agreements',
      index: 9,
      pass: resource.accepted_agreement,
      fail: ((review && !resource.accepted_agreement) && <p className="error-text" id="agree_err">Terms must be accepted</p>) || false,
      component: <Agreements
        config={config_payments}
        resource={resource}
        setResource={setResource}
        form={change_tenant}
        setAuthorStep={() => setStep(steps.find((l) => l.name === 'Authors'))}
      />,
      help: <AgreeHelp type={resource.resource_type.resource_type} />,
      preview: <Agreements config={config_payments} resource={resource} previous={previous} preview />,
    },
  ];

  if (resource.resource_type.resource_type === 'collection') {
    steps.splice(5, 3);
  }

  const markInvalid = () => {
    const et = document.querySelector('.error-text');
    if (et) {
      const ind = et.dataset.index;
      const inv = ind
        ? document.querySelectorAll(`*[aria-errormessage="${et.id}"]`)[ind]
        : document.querySelector(`*[aria-errormessage="${et.id}"]`);
      if (inv) inv.setAttribute('aria-invalid', true);
    }
  };

  const move = async (dir) => {
    /* eslint-disable-next-line no-undef */
    await awaitSelector('.saving_text[hidden]');
    setStep(steps[steps.findIndex((l) => l.name === step.name) + dir] || (dir === -1 && {name: 'Create a submission'}));
  };

  useEffect(() => {
    if (!review) {
      const url = location.search.slice(1);
      if (url) {
        const n = steps.find((c) => url === c.name.split(/[^a-z]/i)[0].toLowerCase());
        if (n.name !== step.name) setStep(n);
      }
    }
  }, [review, location]);

  useEffect(() => {
    const main = document.getElementById('maincontent');
    if (review && step.name === 'Create a submission') {
      main.classList.add('submission-review');
    } else if (review) {
      main.classList.remove('submission-review');
    } else if (step.name !== 'Create a submission') {
      const slug = step.name.split(/[^a-z]/i)[0].toLowerCase();
      const url = window.location.search.slice(1);
      if (slug !== url) window.history.pushState(null, null, `?${slug}`);
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
      observer.observe(subRef.current, {subtree: true, childList: true, attributeFilter: ['id', 'data-index']});
    }
  }, [subRef.current]);

  useEffect(() => {
    if (!review) {
      const url = window.location.search.slice(1);
      if (url) {
        setStep(steps.find((c) => url === c.name.split(/[^a-z]/i)[0].toLowerCase()));
      } else if (steps.find((c) => c.fail || c.pass)) {
        setStep(steps.find((c) => !c.pass));
      }
    } else if (resource.identifier.publication_date) {
      document.querySelector('#submission-checklist li:last-child button').setAttribute('disabled', true);
    }
  }, []);

  if (review) {
    return (
      <>
        <h1>{upCase(resource.resource_type.resource_type)} submission preview{step.name !== 'Create a submission' ? ' editor' : ''}</h1>
        <nav aria-label="Submission editing" className={step.name !== 'Create a submission' ? 'screen-reader-only' : null}>
          <Checklist steps={steps} step={{}} setStep={setStep} open />
        </nav>
        {step.name === 'Create a submission' && (
          <>
            <div id="submission-preview" ref={previewRef} className={user.curator ? 'track-changes' : null}>
              {steps.map((s) => (
                <section key={s.name} aria-label={s.name}>
                  {s.preview}
                  {s.fail}
                </section>
              ))}
            </div>
            <SubmissionForm steps={steps} resource={resource} previewRef={previewRef} authenticityToken={authenticity_token} curator={user.curator} />
          </>
        )}
        <dialog id="submission-step" open={step.name !== 'Create a submission' || null}>
          {step.name !== 'Create a submission' && (
            <div className="submission-edit">
              <nav id="submission-nav" className="open" aria-label="Back">
                <div style={{textAlign: 'right', fontSize: '1.3rem'}}>
                  <button
                    type="button"
                    className="checklist-link"
                    autoFocus
                    aria-controls="submission-step"
                    aria-expanded="true"
                    onClick={() => setStep({name: 'Create a submission'})}
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
                    <div id="submission-header">
                      <h2 className="o-heading__level2">{step.name}</h2>
                      <div role="status">
                        <div className="saving_text" hidden>Saving&hellip;</div>
                        <div className="saved_text" hidden>All progress saved</div>
                      </div>
                    </div>
                    {step.component}
                    {steps.find((s) => s.name === step.name).fail}
                  </div>
                  <div id="submission-help">
                    <button
                      type="button"
                      className="o-button__plain-text2"
                      onClick={() => setStep({name: 'Create a submission'})}
                    >
                      Preview changes
                    </button>
                    <div id="submission-help-text">
                      {step.help}
                    </div>
                    <i className="fas fa-circle-question" aria-hidden="true" />
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
    <>
      <h1>{upCase(resource.resource_type.resource_type)} submission</h1>
      <div className="submission-edit">
        <ChecklistNav steps={steps} step={step} setStep={setStep} open={open} setOpen={setOpen} />
        <div id="submission-wizard" className={open ? 'open' : null}>
          <div id="submission-step" role="region" aria-label={step.name} aria-live="polite" aria-describedby="submission-help-text">
            <div ref={subRef}>
              <div id="submission-header">
                <h2 className="o-heading__level2">{step.name}</h2>
                <div role="status">
                  <div className="saving_text" hidden>Saving&hellip;</div>
                  <div className="saved_text" hidden>All progress saved</div>
                </div>
              </div>
              {step.name === 'Create a submission' && (<SubmissionHelp type={resource.resource_type.resource_type} />)}
              {step.component}
              {!['Create a submission', 'README'].includes(step.name) && (
                steps.find((s) => s.name === step.name).fail
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
                      setStep({name: 'Create a submission'});
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
                    onClick={() => move(1)}
                  >
                  Next <i className="fa fa-caret-right" aria-hidden="true" />
                  </button>
                )}
                {step.name !== 'Create a submission' && (
                  <button
                    type="button"
                    className="o-button__plain-text"
                    aria-controls="submission-step"
                    onClick={() => move(-1)}
                  >
                    <i className="fa fa-caret-left" aria-hidden="true" /> Previous
                  </button>
                )}
              </div>
              <div id="submission-help-text" aria-label="Section help">
                {step.name === 'Create a submission' && (
                  <p>Questions? Check this spot for helpful information about each step!</p>
                )}
                {step.help}
              </div>
              <i className="fas fa-circle-question" aria-hidden="true" />
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default function SubmissionWrapper(props) {
  return <BrowserRouter><Submission {...props} /></BrowserRouter>;
}
