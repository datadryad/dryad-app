import React, {
  Fragment, useRef, useState, useEffect,
} from 'react';
import axios from 'axios';
import {BrowserRouter, useLocation} from 'react-router-dom';
import {upCase} from '../../lib/utils';
import ChecklistNav, {Checklist} from '../components/Checklist';
import SubmissionForm from '../components/SubmissionForm';
import ExitButton from '../components/ExitButton';
import Payments from '../components/Payments';
import Publication, {PubPreview, publicationPass, publicationFail} from '../components/MetadataEntry/Connect';
import TitleImport, {TitlePreview, titleFail} from '../components/MetadataEntry/Title';
import Authors, {AuthPreview, authorCheck} from '../components/MetadataEntry/Authors';
import Compliance, {CompPreview, complianceCheck} from '../components/MetadataEntry/Compliance';
import Description, {DescPreview, abstractCheck} from '../components/MetadataEntry/Description';
import Subjects, {SubjPreview, keywordPass, keywordFail} from '../components/MetadataEntry/Subjects';
import Support, {SuppPreview, fundingCheck} from '../components/MetadataEntry/Support';
import RelatedWorks, {WorksPreview, worksCheck} from '../components/MetadataEntry/RelatedWorks';
import UploadFiles, {FilesPreview, filesCheck} from '../components/UploadFiles';
import ReadMeWizard, {ReadMePreview, readmeCheck} from '../components/ReadMeWizard';
import Agreements from '../components/MetadataEntry/Agreements';
import SubmissionHelp, {
  PublicationHelp, TitleHelp, AuthHelp, DescHelp, SubjHelp, SuppHelp, CompHelp, FilesHelp, ReadMeHelp, WorksHelp, AgreeHelp,
} from '../components/SubmissionHelp';
/* eslint-disable jsx-a11y/no-autofocus */

function Submission({
  submission, user, s3_dir_name, config_s3, config_maximums, config_payments, config_cedar, change_tenant,
}) {
  const location = useLocation();
  const subRef = useRef([]);
  const previewRef = useRef(null);
  const [resource, setResource] = useState(JSON.parse(submission));
  const [step, setStep] = useState({name: 'Create a submission'});
  const [open, setOpen] = useState(window.innerWidth > 600);
  const [review, setReview] = useState(!!resource.identifier.process_date.processing || !!resource.accepted_agreement);
  const [payment, setPayment] = useState(false);
  const [fees, setFees] = useState({});
  const previous = resource.previous_curated_resource;
  const observers = [];

  const steps = () => {
    const stepArray = [{
      name: 'Connect',
      pass: publicationPass(resource),
      fail: (review || publicationPass(resource)) && publicationFail(resource, review),
      component: <Publication current={step.name === 'Connect'} resource={resource} setResource={setResource} />,
      help: <PublicationHelp />,
      preview: <PubPreview resource={resource} previous={previous} curator={user.curator} />,
    }, {
      name: 'Title',
      pass: resource.title,
      fail: (review || step.index > 0) && titleFail(resource),
      component: <TitleImport current={step.name === 'Title'} resource={resource} setResource={setResource} />,
      help: <TitleHelp />,
      preview: <TitlePreview resource={resource} previous={previous} />,
    },
    {
      name: 'Authors',
      pass: resource.authors.length > 0 && !authorCheck(resource),
      fail: (review || step.index > 1) && authorCheck(resource),
      component: <Authors current={step.name === 'Authors'} resource={resource} setResource={setResource} user={user} />,
      help: <AuthHelp />,
      preview: <AuthPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Description',
      pass: !abstractCheck(resource),
      fail: (review || step.index > 2) && abstractCheck(resource),
      component: <Description
        current={step.name === 'Description'}
        resource={resource}
        setResource={setResource}
        curator={user.curator}
        cedar={config_cedar}
      />,
      help: <DescHelp type={resource.resource_type.resource_type} />,
      preview: <DescPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Subjects',
      pass: keywordPass(resource.subjects),
      fail: (review || step.index > 3) && keywordFail(resource),
      component: <Subjects current={step.name === 'Subjects'} resource={resource} setResource={setResource} />,
      help: <SubjHelp />,
      preview: <SubjPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Support',
      pass: !fundingCheck(resource.contributors.filter((f) => f.contributor_type === 'funder')),
      fail: (review || step.index > 4) && fundingCheck(resource.contributors.filter((f) => f.contributor_type === 'funder')),
      component: <Support current={step.name === 'Support'} resource={resource} setResource={setResource} />,
      help: <SuppHelp type={resource.resource_type.resource_type} />,
      preview: <SuppPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Compliance',
      pass: !complianceCheck(resource),
      fail: (review || step.index > 5) && complianceCheck(resource),
      component: <Compliance current={step.name === 'Compliance'} resource={resource} setResource={setResource} />,
      help: <CompHelp />,
      preview: <CompPreview resource={resource} previous={previous} />,
    },
    {
      name: 'Files',
      pass: resource.generic_files?.length > 0,
      fail: (review || step.index > 6) && filesCheck(resource, user.superuser, config_maximums),
      component: resource.generic_files === undefined ? <p><i className="fas fa-spinner fa-spin" /></p> : (
        <UploadFiles
          {...{
            resource, setResource, previous, s3_dir_name, config_s3, config_maximums, config_payments,
          }}
          current={step.name === 'Files'}
        />
      ),
      help: <FilesHelp date={resource.identifier.publication_date} maxFiles={config_maximums.files} />,
      preview: resource.generic_files === undefined ? <p><i className="fas fa-spinner fa-spin" /></p> : (
        <FilesPreview resource={resource} previous={previous} curator={user.curator} maxSize={config_maximums.merritt_size} />
      ),
    },
    {
      name: 'README',
      pass: resource.descriptions.find((d) => d.description_type === 'technicalinfo')?.description,
      fail: (review || step.index > 7) && readmeCheck(resource),
      component: <ReadMeWizard resource={resource} setResource={setResource} current={step.name === 'README'} />,
      help: <ReadMeHelp />,
      preview: <ReadMePreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Related works',
      pass: resource.related_identifiers.some((ri) => !!ri.related_identifier && ri.work_type !== 'primary_article') || resource.accepted_agreement,
      fail: worksCheck(resource, (review || step.index > 8)),
      component: <RelatedWorks current={step.name === 'Related works'} resource={resource} setResource={setResource} />,
      help: <WorksHelp setTitleStep={() => setStep(steps().find((l) => l.name === 'Title'))} />,
      preview: <WorksPreview resource={resource} previous={previous} curator={user.curator} />,
    },
    {
      name: 'Agreements',
      pass: resource.accepted_agreement,
      fail: ((review && !resource.accepted_agreement) && <p className="error-text" id="agree_err">Terms must be accepted</p>) || false,
      component: <Agreements
        resource={resource}
        setResource={setResource}
        current={step.name === 'Agreements'}
        subFees={fees}
        setSubFees={setFees}
        config={config_payments}
        form={change_tenant}
        user={user}
        setAuthorStep={() => setStep(steps().find((l) => l.name === 'Authors'))}
      />,
      help: <AgreeHelp type={resource.resource_type.resource_type} />,
      preview: <Agreements
        {...{
          resource, setResource, user, previous,
        }}
        config={config_payments}
        subFees={fees}
        setSubFees={setFees}
        form={change_tenant}
        user={user}
        setAuthorStep={() => setStep(steps().find((l) => l.name === 'Authors'))}
        preview
      />,
    }];
    return stepArray.map((s, i) => {
      s.index = i;
      return s;
    });
  };

  if (resource.resource_type.resource_type === 'collection') {
    steps().splice(5, 3);
  }

  const recheckPayer = () => {
    axios.get(`/resources/${resource.id}/payer_check`)
      .then(({data}) => {
        setResource((res) => ({
          ...res,
          identifier: {
            ...res.identifier,
            new_upload_size_limit: data.new_upload_size_limit,
          },
        }));
      });
  };

  useEffect(() => {
    recheckPayer();
  }, [resource.authors, resource.journal, resource.contributors]);

  const markInvalid = (el) => {
    const et = el.querySelector('.error-text');
    if (et) {
      const ind = et.dataset.index;
      const inv = ind
        ? el.querySelectorAll(`*[aria-errormessage="${et.id}"]`)[ind]
        : el.querySelector(`*[aria-errormessage="${et.id}"]`);
      if (inv) inv.setAttribute('aria-invalid', true);
    }
  };

  const move = async (dir) => {
    /* eslint-disable-next-line no-undef */
    await awaitSelector('.saving_text[hidden]');
    setStep(steps()[steps().findIndex((l) => l.name === step.name) + dir] || (dir === -1 && {name: 'Create a submission'}));
  };

  useEffect(() => {
    if (!review) {
      const url = location.search.slice(1);
      if (url) {
        const n = steps().find((c) => url === c.name.split(/[^a-z]/i)[0].toLowerCase());
        if (n.name !== step.name) setStep(n);
      }
    }
  }, [review, location]);

  useEffect(() => {
    const url = window.location.search.slice(1);
    const main = document.getElementById('maincontent');
    if (payment === 'paid') {
      document.getElementById('submit_form').submit();
    } else if (payment) {
      main.classList.remove('submission-review');
      window.history.pushState(null, null, '?payment');
    } else if (review && step.name === 'Create a submission') {
      main.classList.add('submission-review');
      if (url) document.querySelector(`*[data-slug=${url}]`)?.focus();
      window.history.pushState(null, null, null);
    } else if (review) {
      main.classList.remove('submission-review');
    } else {
      document.querySelector('#submission-header h2')?.focus();
    }
    if (step.name !== 'Create a submission') {
      const slug = step.name.split(/[^a-z]/i)[0].toLowerCase();
      if (slug !== url) window.history.pushState(null, null, `?${slug}`);
    }
  }, [review, step, payment]);

  useEffect(() => {
    if (subRef.current.length === steps().length) {
      steps().forEach((s, i) => {
        if (subRef.current[i]) {
          markInvalid(subRef.current[i]);
          observers[i] = new MutationObserver(() => {
            if (subRef.current[i]) {
              const old = subRef.current[i].querySelector('*[aria-invalid]');
              if (old) old.removeAttribute('aria-invalid');
              markInvalid(subRef.current[i]);
            } else { observers[i].disconnect(); }
          });
          observers[i].observe(subRef.current[i], {subtree: true, childList: true, attributeFilter: ['id', 'data-index']});
        }
      });
    }
  }, [subRef.current]);

  useEffect(() => {
    async function getFileData() {
      axios.get(`/stash_datacite/metadata_entry_pages/${resource.id}/files`).then((data) => {
        const {generic_files, previous_files} = data.data;
        if (previous && previous_files) previous.generic_files = previous_files;
        setResource((r) => ({...r, generic_files, previous_curated_resource: previous}));
      });
    }
    if (!review) {
      const url = window.location.search.slice(1);
      if (url) {
        setStep(steps().find((c) => url === c.name.split(/[^a-z]/i)[0].toLowerCase()));
      } else if (steps().find((c) => c.fail || c.pass)) {
        setStep(steps().find((c) => !c.pass));
      }
    } else {
      document.documentElement.classList.add('preview_submission');
      if (resource.identifier.publication_date) {
        document.querySelector('#submission-checklist li:last-child button').setAttribute('disabled', true);
      }
    }
    getFileData();
  }, []);

  if (review) {
    return (
      <>
        <div id="submission-heading">
          <div>
            <h1>
              {upCase(resource.resource_type.resource_type)} submission
              {payment ? ' payment' : ' preview'}
              {step.name !== 'Create a submission' ? ' editor' : ''}
            </h1>
            {payment ? (
              <button className="o-button__plain-text7" type="button" onClick={() => setPayment(false)}>
                <i className="fas fa-circle-left" aria-hidden="true" />Back to preview
              </button>
            ) : <ExitButton resource={resource} />}
          </div>
        </div>
        <nav aria-label="Submission editing" className={step.name !== 'Create a submission' || payment ? 'screen-reader-only' : null}>
          <Checklist steps={steps} step={{}} setStep={setStep} open />
        </nav>
        {step.name === 'Create a submission' && (
          <>
            <div id="submission-preview" ref={previewRef} className={`${user.curator ? 'track-changes' : ''} ${payment ? 'screen-reader-only' : ''}`}>
              {steps().map((s) => (
                <section key={s.name} aria-label={s.name}>
                  {s.preview}
                  {s.fail}
                </section>
              ))}
            </div>
            <SubmissionForm {...{
              steps, resource, fees, payment, setPayment, previewRef, user,
            }}
            />
          </>
        )}
        <dialog id="submission-step" open={step.name !== 'Create a submission' || payment || null}>
          {payment && (
            <div className="submission-edit">
              <Payments config={config_payments} resource={resource} setResource={setResource} setPayment={setPayment} />
            </div>
          )}
          <div className="submission-edit" hidden={step.name === 'Create a submission' || null}>
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
              <div>
                <div>
                  <div id="submission-header">
                    <h2 className="o-heading__level2">{step.name}</h2>
                    <div role="status">
                      <div className="saving_text" hidden>Saving&hellip;</div>
                      <div className="saved_text" hidden>All progress saved</div>
                    </div>
                  </div>
                  {steps().map((s, i) => (
                    <div hidden={step.name !== s.name || null} key={s.name} ref={(el) => { subRef.current[i] = el; }}>
                      {s.component}
                      {steps().find((si) => si.name === s.name).fail}
                    </div>
                  ))}
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
        </dialog>
      </>
    );
  }

  return (
    <>
      <div id="submission-heading">
        <div>
          <h1>{upCase(resource.resource_type.resource_type)} submission</h1>
        </div>
      </div>
      <div className="submission-edit">
        <ChecklistNav steps={steps} step={step} setStep={setStep} open={open} setOpen={setOpen} />
        <div id="submission-wizard" className={open ? 'open' : null}>
          <div id="submission-step" role="region" aria-label={step.name} aria-live="polite" aria-describedby="submission-help-text">
            <div>
              <div id="submission-header">
                <h2 className="o-heading__level2" tabIndex="-1">{step.name}</h2>
                <div role="status">
                  <div className="saving_text" hidden>Saving&hellip;</div>
                  <div className="saved_text" hidden>All progress saved</div>
                </div>
              </div>
              {step.name === 'Create a submission' && (<SubmissionHelp type={resource.resource_type.resource_type} />)}
              {steps().map((s, i) => (
                <div hidden={step.name !== s.name || null} key={s.name} ref={(el) => { subRef.current[i] = el; }}>
                  {s.component}
                  {s.name !== 'README' && (
                    steps().find((si) => si.name === s.name).fail
                  )}
                </div>
              ))}
            </div>
            <div id="submission-help">
              <div className="dataset-nav-container">
                <div className="dataset-nav">
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
                <div className="dataset-nav-ltr">
                  <ExitButton resource={resource} />
                </div>
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
