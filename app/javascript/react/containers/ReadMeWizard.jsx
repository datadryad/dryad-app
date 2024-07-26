import React, {useState, useEffect, useCallback} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {debounce} from 'lodash';
import ReadMeImport from '../components/ReadMeWizard/ReadMeImport';
import ReadMeSteps, {secTitles} from '../components/ReadMeWizard/ReadMeSteps';
import MarkdownEditor from '../components/MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../lib/utils';

export default function ReadMe({
  dcsDescription, title, doi, fileList, updatePath, fileContent,
}) {
  const [initialValue, setInitialValue] = useState(null);
  const [replaceValue, setReplaceValue] = useState(null);
  const [wizardContent, setWizardContent] = useState(null);
  const [wizardStep, setWizardStep] = useState(0);

  const saveDescription = (markdown) => {
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const data = {
      authenticity_token,
      description: {
        description: markdown,
        resource_id: dcsDescription.resource_id,
        id: dcsDescription.id,
      },
    };
    showSavingMsg();
    axios.patch(updatePath, data, {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}})
      .then(() => {
        showSavedMsg();
      });
  };

  const checkDescription = useCallback(debounce(saveDescription, 900), []);

  const assembleValue = () => {
    let v = `# ${wizardContent.title}\n\n[${wizardContent.doi}](${wizardContent.doi})\n\n## Description of the data and file structure\n\n`;
    if (wizardContent.step1) v += wizardContent.step1;
    if (wizardContent.step2) v += `### ${secTitles[1]}\n\n${wizardContent.step2}`;
    [3, 4].forEach((s) => {
      if (wizardContent[`step${s}`]) {
        v += `## ${secTitles[s - 1]}\n\n${wizardContent[`step${s}`]}`;
      }
    });
    return v;
  };

  const restartWizard = () => {
    setInitialValue(null);
    setWizardContent({title, doi, step: 0});
    setWizardStep(0);
    saveDescription(null);
  };

  useEffect(() => {
    if (initialValue) {
      document.getElementById('proceed_review').removeAttribute('hidden');
      document.querySelector('.c-autosave-footer').removeAttribute('hidden');
    }
  }, [initialValue]);

  useEffect(() => {
    if (wizardStep > secTitles.length) {
      const complete = assembleValue();
      saveDescription(complete);
      setInitialValue(complete);
    } else if (wizardStep > 0) {
      wizardContent.step = wizardStep;
      saveDescription(JSON.stringify(wizardContent));
    }
  }, [wizardStep]);

  useEffect(() => {
    if (dcsDescription.description) {
      try {
        const template = JSON.parse(dcsDescription.description);
        setWizardContent(template);
        setWizardStep(template.step);
      } catch {
        setInitialValue(dcsDescription.description);
      }
    } else if (fileContent) {
      setInitialValue(fileContent);
    } else {
      setWizardContent({title, doi, step: 0});
    }
  }, []);

  if (initialValue) {
    return (
      <>
        <div className="readme-columns-final">
          <div>
            <p style={{marginTop: 0}}>
              To help others interpret and reuse your dataset, a README file must be included, containing
              abbreviations and codes, file descriptions, and information about any necessary software.{' '}
              <a href="/stash/best_practices#describe-your-dataset-in-a-readme-file" target="_blank">
                <i className="far fa-file-lines" aria-hidden="true" style={{marginRight: '.5ch'}} />Learn about README files
                <span className="screen-reader-only"> (opens in new window)</span>
              </a>
            </p>
            <p>
              You can copy and paste formatted text into the editor, or enter markdown by clicking the &apos;Markdown&apos; tab.
            </p>
          </div>
          <div>
            <p>You can replace the content below with a local README file in <a href="https://www.markdownguide.org/" target="_blank" rel="noreferrer">markdown format<span className="screen-reader-only"> (opens in new window)</span></a>, or by deleting the content and generating a new README using our tool.</p>
            <div className="readme-buttons">
              <ReadMeImport title="Import new README" setValue={setReplaceValue} />
              <button type="button" className="o-button__plain-text0" onClick={restartWizard}>
                <i className="fa fa-trowel-bricks" aria-hidden="true" /> Generate new README
              </button>
            </div>
          </div>
        </div>
        <MarkdownEditor
          id="readme_editor"
          initialValue={initialValue}
          replaceValue={replaceValue}
          onChange={checkDescription}
        />
      </>
    );
  } if (wizardContent && wizardStep <= secTitles.length) {
    if (wizardStep === 0) {
      return (
        <div style={{height: '100%'}}>
          <div style={{maxWidth: '90ch'}}>
            <p style={{marginTop: 0}}>
              Your Dryad submission must be accompanied by a README file, to help others use and understand your
              dataset. It should contain the details needed to interpret and reuse your data, including abbreviations
              and codes, file descriptions, and information about any necessary software.
            </p>
            <p style={{textAlign: 'center'}}>
              <a href="/stash/best_practices#describe-your-dataset-in-a-readme-file" target="_blank">
                <i className="far fa-file-lines" aria-hidden="true" style={{marginRight: '.5ch'}} />Learn about README files
                <span className="screen-reader-only"> (opens in new window)</span>
              </a>
            </p>
          </div>
          <div className="readme-columns">
            <div>
              <h2 className="o-heading__level2">Need to create a README?</h2>
              <p>Use our step-by-step tool to generate a README file. After completion your generated README can be added to and revised.</p>
              <p style={{textAlign: 'center'}}>
                <button type="button" className="o-button__plain-text1" onClick={() => setWizardStep(1)}>
                  Build a README <i className="fa fa-trowel-bricks fa-flip-horizontal" aria-hidden="true" />
                </button>
              </p>
            </div>
            <div>
              <h2 className="o-heading__level2">Already have a README file?</h2>
              <p>If you already have a README file in <a href="https://www.markdownguide.org/" target="_blank" rel="noreferrer">markdown format<span className="screen-reader-only"> (opens in new window)</span></a> for your dataset, you can import it here. </p>
              <ReadMeImport setValue={setInitialValue} />
            </div>
          </div>
        </div>
      );
    }
    return (
      <ReadMeSteps
        key={wizardStep}
        content={wizardContent}
        step={wizardStep}
        setStep={setWizardStep}
        fileList={fileList}
        save={checkDescription}
      />
    );
  }
  return (
    <p style={{display: 'flex', alignItems: 'center'}}>
      <img src="../../../images/spinner.gif" alt="Loading spinner" style={{height: '1.5rem', marginRight: '.5ch'}} />
          Loading README generator
    </p>
  );
}

ReadMe.propTypes = {
  dcsDescription: PropTypes.object.isRequired,
  updatePath: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  doi: PropTypes.string.isRequired,
  fileContent: PropTypes.string,
  fileList: PropTypes.array,
};
