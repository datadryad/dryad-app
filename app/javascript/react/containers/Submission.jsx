import React, {useRef, useState, useEffect} from 'react';
import {upCase} from '../../lib/utils';
import Checklist from '../components/Checklist';
import Publication, {publicationCheck} from '../components/MetadataEntry/Publication';
import Authors, {authorCheck} from '../components/MetadataEntry/Authors';
import Support, {fundingCheck} from '../components/MetadataEntry/Support';
import Subjects, {keywordPass, keywordFail} from '../components/MetadataEntry/Subjects';
import Description, {abstractCheck} from '../components/MetadataEntry/Description';
import RelatedWorks, {worksCheck} from '../components/MetadataEntry/RelatedWorks';
import UploadFiles, {filesCheck} from '../components/UploadFiles';
import ReadMeWizard, {readmeCheck} from '../components/ReadMeWizard';

export default function Submission({
  submission, ownerId, admin, s3_dir_name, config_s3, config_frictionless, config_cedar,
}) {
  const subRef = useRef();
  const [resource, setResource] = useState(JSON.parse(submission));
  const [step, setStep] = useState({name: 'Start'});
  const [open, setOpen] = useState(false);

  const steps = [
    {
      name: 'Title/Import',
      pass: !!resource.title,
      fail: publicationCheck(resource),
      component: <Publication resource={resource} setResource={setResource} />,
    },
    {
      name: 'Authors',
      pass: !!resource.title && resource.authors.length > 0,
      fail: !!resource.title && authorCheck(resource.authors, ownerId),
      component: <Authors resource={resource} setResource={setResource} admin={admin} ownerId={ownerId} />,
    },
    {
      name: 'Support',
      pass: resource.contributors.find((c) => c.contributor_type === 'funder'),
      fail: fundingCheck(resource.contributors.filter((f) => f.contributor_type === 'funder')),
      component: <Support resource={resource} setResource={setResource} />,
    },
    {
      name: 'Subjects',
      pass: keywordPass(resource.subjects),
      fail: keywordFail(resource.subjects),
      component: <Subjects resource={resource} setResource={setResource} />,
    },
    {
      name: 'Description',
      pass: resource.descriptions.some((d) => !!d.description),
      fail: abstractCheck(resource),
      component: <Description resource={resource} setResource={setResource} admin={admin} cedar={config_cedar} />,
    },
    {
      name: 'Files',
      pass: resource.generic_files.length > 0,
      fail: filesCheck(resource.generic_files),
      component: <UploadFiles
        resource={resource}
        setResource={setResource}
        s3_dir_name={s3_dir_name}
        config_s3={config_s3}
        config_frictionless={config_frictionless}
      />,
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
    },
    {
      name: 'Related works',
      pass: resource.related_identifiers.some((rid) => !!rid.related_identifier) || resource.accepted_agreement,
      fail: worksCheck(resource),
      component: <RelatedWorks resource={resource} setResource={setResource} />,
    },
    {
      name: 'Agreements',
      pass: resource.accepted_agreement,
      fail: false,
    },
  ];

  useEffect(() => {
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

  useEffect(() => {
    if (steps.find((c) => c.fail) || steps.findLast((c) => c.pass)) {
      setStep(steps.find((c) => c.fail) || steps[steps.findLastIndex((c) => c.pass) + 1]);
      setOpen('start');
    }
  }, []);

  return (
    <>
      <Checklist steps={steps} step={step} setStep={setStep} open={open} setOpen={setOpen} />
      <div id="submission-wizard" className={(step.name === 'Start' && 'start') || (open && 'open') || ''}>
        <div>
          <div ref={subRef}>
            <h1>{upCase(resource.resource_type.resource_type)} submission</h1>
            {step.component}
            {step.name === 'Start' && (
              <p>Complete the checklist, and submit your data for publication.</p>
            )}
            {!['Start', 'README'].includes(step.name) && (
              steps.find((s) => s.name === step.name).pass && steps.find((s) => s.name === step.name).fail
            )}
          </div>
          <div className="o-dataset-nav">
            <div className="o-dataset-nav">
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
              <div className="saving_text" hidden>Saving&hellip;</div>
              <div className="saved_text" hidden>All progress saved</div>
            </div>
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
        </div>
      </div>
    </>
  );
}
