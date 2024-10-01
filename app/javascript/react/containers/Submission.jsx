import React, {useState, useEffect} from 'react';
import {upCase} from '../../lib/utils';
import Checklist from '../components/Checklist';
import Publication from '../components/MetadataEntry/Publication';
import Authors from '../components/MetadataEntry/Authors';
import Support from '../components/MetadataEntry/Support';
import Subjects from '../components/MetadataEntry/Subjects';
import Description from '../components/MetadataEntry/Description';
import RelatedWorks from '../components/MetadataEntry/RelatedWorks';
import UploadFiles from './UploadFiles';
import ReadMeWizard from './ReadMeWizard';

export default function Submission({
  submission, ownerId, admin, s3_dir_name, config_s3, config_frictionless,
}) {
  const [resource, setResource] = useState(JSON.parse(submission));
  const [step, setStep] = useState({name: 'Start'});
  const [open, setOpen] = useState(false);

  const steps = [
    {
      name: 'Title/Import',
      pass: !!resource.title,
      fail: false,
      component: <Publication resource={resource} setResource={setResource} />,
    },
    {
      name: 'Authors',
      pass: !!resource.title && resource.authors.length > 0,
      fail: false,
      component: <Authors resource={resource} setResource={setResource} admin={admin} ownerId={ownerId} />,
    },
    {
      name: 'Support',
      pass: resource.contributors.find((c) => c.contributor_type === 'funder' && !!c.name_identifier_id),
      fail: false,
      component: <Support resource={resource} setResource={setResource} />,
    },
    {
      name: 'Subjects',
      pass: resource.subjects.length > 3,
      fail: false,
      component: <Subjects resource={resource} setResource={setResource} />,
    },
    {
      name: 'Description',
      pass: !!resource.descriptions.find((d) => d.description_type === 'abstract')?.description,
      fail: false,
      component: <Description resource={resource} setResource={setResource} admin={admin} />,
    },
    {
      name: 'Files',
      pass: resource.generic_files.filter((f) => f.type === 'StashEngine::DataFile').length > 0,
      fail: false,
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
      pass: !!resource.descriptions.find((d) => d.description_type === 'technical_info')?.description,
      fail: false,
      component: <ReadMeWizard resource={resource} setResource={setResource} />,
    },
    {
      name: 'Related works',
      pass: false,
      fail: false,
      component: <RelatedWorks resource={resource} setResource={setResource} />,
    },
    {
      name: 'Agreements',
      pass: resource.accepted_agreement,
      fail: false,
    },
  ];

  useEffect(() => setStep(steps.findLast((c) => c.pass) || {name: 'Start'}), []);
  // useEffect(() => setDisabled(false), [step])

  return (
    <>
      <Checklist steps={steps} step={step} setStep={setStep} open={open} setOpen={setOpen} />
      <div id="submission-wizard" className={(step.name === 'Start' && 'start') || (open && 'open') || ''}>
        <div>
          <div>
            <h1>{upCase(resource.resource_type.resource_type)} submission</h1>
            {step.component}
            {step.name === 'Start' && (
              <p>Complete the checklist, and submit your data for publication.</p>
            )}
          </div>
          <div className="o-dataset-nav">
            <div className="o-dataset-nav">
              <button
                type="button"
                className="o-button__plain-text2"
                onClick={() => setStep(steps[steps.findIndex((l) => l.name === step.name) + 1])}
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
                onClick={() => setStep(steps[steps.findIndex((l) => l.name === step.name) - 1] || {name: 'Start'})}
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
