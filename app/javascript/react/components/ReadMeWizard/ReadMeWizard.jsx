import React, {useState, useEffect, useCallback} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {debounce} from 'lodash';
import ReadMeImport from './ReadMeImport';
import ReadMeSteps, {secTitles} from './ReadMeSteps';
import MarkdownEditor from '../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export default function ReadMe({dcsDescription, resource, setResource}) {
  const [initialValue, setInitialValue] = useState(null);
  const [replaceValue, setReplaceValue] = useState(null);
  const [fileList, setFileList] = useState([]);
  const [wizardContent, setWizardContent] = useState(null);
  const [wizardStep, setWizardStep] = useState(0);

  const saveDescription = (markdown) => {
    const authenticity_token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');
    const subJson = {
      authenticity_token,
      description: {
        description: markdown,
        resource_id: dcsDescription.resource_id,
        id: dcsDescription.id,
      },
    };
    showSavingMsg();
    axios.patch(
      '/stash_datacite/descriptions/update',
      subJson,
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        const {description_type} = data.data;
        setResource((r) => ({...r, descriptions: [data.data, ...r.descriptions.filter((d) => d.description_type !== description_type)]}));
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
    // deal with arrows?
    setInitialValue(null);
    setReplaceValue(null);
    setWizardContent({title: resource.title, doi: resource.identifier.identifier, step: 0});
    setWizardStep(0);
    saveDescription(null);
  };

  useEffect(() => {
    if (initialValue) {
      // deal with arrows?
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
    async function getFiles() {
      axios.get(`/stash/resources/${resource.id}/prepare_readme`).then((data) => {
        const {file_list, readme_file} = data.data;
        setFileList(file_list);
        if (readme_file) {
          setInitialValue(readme_file);
        } else if (!dcsDescription.description) {
          setWizardContent({title: resource.title, doi: resource.identifier.identifier, step: 0});
        }
      });
    }
    if (dcsDescription.description) {
      try {
        const template = JSON.parse(dcsDescription.description);
        setWizardContent(template);
        setWizardStep(template.step);
      } catch {
        setInitialValue(dcsDescription.description);
      }
    }
    getFiles();
  }, []);

  if (initialValue || replaceValue) {
    return (
      <>
        <h2>README</h2>
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
              <button
                type="button"
                className="o-button__plain-text0"
                aria-controls="restart-wizard-dialog"
                onClick={() => document.getElementById('restart-wizard-dialog').showModal()}
              >
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
        <dialog
          id="restart-wizard-dialog"
          className="modalDialog"
          role="alertdialog"
          aria-labelledby="readme-alert-title"
          aria-describedby="readme-alert-desc"
          aria-modal="true"
        >
          <div className="modalClose">
            <button aria-label="Close" type="button" onClick={() => document.getElementById('restart-wizard-dialog').close()} />
          </div>
          <div>
            <h1 id="readme-alert-title">Are you sure?</h1>
            <p id="readme-alert-desc">
              Are you sure you want to delete this README and use our tool to generate a new one? This action may not be reversible.
            </p>
            <div className="c-modal__buttons-right">
              <button
                type="button"
                className="o-button__plain-text2"
                onClick={() => {
                  document.getElementById('restart-wizard-dialog').close();
                  restartWizard();
                }}
              >Delete &amp; restart
              </button>
              <button type="button" className="o-button__plain-text7" onClick={() => document.getElementById('restart-wizard-dialog').close()}>
                Cancel
              </button>
            </div>
          </div>
        </dialog>
      </>
    );
  } if (wizardContent && wizardStep <= secTitles.length) {
    if (wizardStep === 0) {
      return (
        <div style={{height: '100%'}}>
          <div style={{maxWidth: '90ch'}}>
            <p style={{marginTop: 0}}>
              Your Dryad submission must be accompanied by a{' '}
              <a href="/stash/best_practices#describe-your-dataset-in-a-readme-file" target="_blank">
                README file<span className="screen-reader-only"> (opens in new window)</span>
              </a>, to help others use and understand your
              dataset. It should contain the details needed to interpret and reuse your data, including abbreviations
              and codes, file descriptions, and information about any necessary software.
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
              <ReadMeImport setValue={setReplaceValue} />
            </div>
          </div>
          <div style={{maxWidth: '90ch', marginBottom: '2rem'}}>
            <h2>Need an example?</h2>
            <p>Here are some outstanding READMEs from Dryad submissions, which show the following:</p>
            <ul className="readme-examples" style={{paddingLeft: '2ch'}}>
              <li>
                <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.h70rxwdq5#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
                  Chromatographic and mass spectrometric analysis data<span className="screen-reader-only"> (opens in new window)</span>
                </a>
              </li>
              <li>
                <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.rr4xgxdg6#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
                MATLAB files<span className="screen-reader-only"> (opens in new window)</span>
                </a>
              </li>
              <li>
                <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.nzs7h44xg#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
                Genomic data<span className="screen-reader-only"> (opens in new window)</span>
                </a>
              </li>
              <li>
                <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.jdfn2z3j3#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
                Neural network deep learning code<span className="screen-reader-only"> (opens in new window)</span>
                </a>
              </li>
              <li>
                <a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.18931zd25#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />
                Genomic VCF and companion scripts<span className="screen-reader-only"> (opens in new window)</span>
                </a>
              </li>
            </ul>
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
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
