/* eslint-disable no-nested-ternary */
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
    [1, 2, 4].forEach((s) => {
      if (wizardContent[`step${s}`]) {
        v += `### ${secTitles[s - 1]}\n\n${wizardContent[`step${s}`]}`;
      }
    });
    [3, 5].forEach((s) => {
      if (wizardContent[`step${s}`]) {
        v += `## ${secTitles[s - 1]}\n\n${wizardContent[`step${s}`]}`;
      }
    });
    return v;
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

  return (
    <>
      <div className="c-autosave-header">
        <h1 className="o-heading__level1" style={{marginBottom: '1rem'}} id="readme-label">Prepare README file</h1>
        <div className="c-autosave__text saving_text" hidden>Saving&hellip;</div>
        <div className="c-autosave__text saved_text" hidden>All progress saved</div>
      </div>
      {initialValue ? (
        <>
          <div className="o-admin-columns">
            <div className="o-admin-left" style={{minWidth: '400px', flexGrow: 2}}>
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
            <div className="o-admin-right cedar-container" style={{minWidth: '500px', flexShrink: 2}}>
              <p>You can replace the content below with a local README file in <a href="https://www.markdownguide.org/" target="_blank" rel="noreferrer">markdown format<span className="screen-reader-only"> (opens in new window)</span></a>.</p>
              <ReadMeImport title="Replace README" setValue={setReplaceValue} />
            </div>
          </div>
          <MarkdownEditor
            id="readme_editor"
            initialValue={initialValue}
            replaceValue={replaceValue}
            onChange={checkDescription}
          />
        </>
      ) : (
        wizardContent && wizardStep <= secTitles.length ? (
          wizardStep === 0 ? (
            <div style={{maxWidth: '90ch', height: '100%'}}>
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
              <div className="o-admin-columns">
                <div className="cedar-container o-admin-left">
                  <h2 className="o-heading__level2">Already have a README file?</h2>
                  <p>If you already have a README file in <a href="https://www.markdownguide.org/" target="_blank" rel="noreferrer">markdown format<span className="screen-reader-only"> (opens in new window)</span></a> for your dataset, you can import it here. </p>
                  <ReadMeImport setValue={setInitialValue} />
                </div>
                <div className="o-admin-right" style={{alignContent: 'center', marginBottom: '20px', textAlign: 'center'}}>
                    Otherwise, please
                  <button type="button" className="o-button__plain-text1" onClick={() => setWizardStep(1)}>
                      Create a README using our tool <i className="fa fa-caret-right" aria-hidden="true" />
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <ReadMeSteps
              key={wizardStep}
              content={wizardContent}
              step={wizardStep}
              setStep={setWizardStep}
              fileList={fileList}
              save={checkDescription}
            />
          )
        ) : (
          <p style={{display: 'flex', alignItems: 'center'}}>
            <img src="../../../images/spinner.gif" alt="Loading spinner" style={{height: '1.5rem', marginRight: '.5ch'}} />
              Loading README generator
          </p>
        )
      )}
    </>
  );
}

ReadMe.propTypes = {
  dcsDescription: PropTypes.object.isRequired,
  updatePath: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  doi: PropTypes.string.isRequired,
  fileContent: PropTypes.string,
};
