import React, {useState, useEffect, useCallback} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import {debounce} from 'lodash';
import ReadMeImport from './ReadMeImport';
import ReadMeSteps, {secTitles} from './ReadMeSteps';
import {ExitIcon} from '../ExitButton';
import MarkdownEditor from '../MarkdownEditor';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

export default function ReadMeWizard({resource, setResource, current}) {
  const [desc, setDesc] = useState(null);
  const [fileList, setFileList] = useState([]);
  const [readmeFile, setReadmeFile] = useState(null);

  const getFiles = async () => {
    axios.get(`/resources/${resource.id}/prepare_readme`).then((data) => {
      const {file_list, readme_file} = data.data;
      setFileList(file_list);
      setReadmeFile(readme_file);
    });
  };

  useEffect(() => {
    if (current) {
      getFiles();
      setDesc(JSON.parse(JSON.stringify(resource.descriptions.find((d) => d.description_type === 'technicalinfo'))));
    }
  }, [current]);

  if (desc?.id) {
    return (
      <ReadMe
        dcsDescription={desc}
        title={resource.title}
        doi={resource.identifier.identifier}
        setResource={setResource}
        fileList={fileList}
        readmeFile={readmeFile}
      />
    );
  }
  return (
    <p style={{display: 'flex', alignItems: 'center', gap: '.5ch'}}>
      <i className="fas fa-spin fa-spinner" aria-hidden="true" />
      Loading README generator
    </p>
  );
}

function ReadMe({
  dcsDescription, title, doi, setResource, fileList, readmeFile,
}) {
  const [initialValue, setInitialValue] = useState(null);
  const [replaceValue, setReplaceValue] = useState(null);
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

  const checkDescription = useCallback(debounce(saveDescription, 500), []);

  const assembleValue = () => {
    let v = `# ${
      wizardContent.title || 'Dryad dataset'
    }\n\nDataset DOI: [${wizardContent.doi}](${wizardContent.doi})\n\n## Description of the data and file structure\n\n`;
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
    setWizardContent({title, doi, step: 0});
    setWizardStep(0);
    saveDescription(null);
  };

  useEffect(() => {
    if (wizardContent?.step) {
      checkDescription(JSON.stringify(wizardContent));
    }
  }, [wizardContent]);

  useEffect(() => {
    if (wizardStep > secTitles.length) {
      const complete = assembleValue();
      checkDescription(complete);
      setInitialValue(complete);
    } else if (wizardStep > 0) {
      setWizardContent((w) => ({...w, step: wizardStep}));
    }
    document.querySelector('.markdown_editor')?.focus();
  }, [wizardStep]);

  useEffect(() => {
    if (dcsDescription.description) {
      try {
        const template = JSON.parse(dcsDescription.description);
        setWizardStep(Number(template.step));
        setWizardContent(template);
      } catch {
        setInitialValue(dcsDescription.description);
      }
    } else if (readmeFile) {
      setReplaceValue(readmeFile);
    } else {
      setWizardContent({title, doi, step: 0});
    }
  }, []);

  if (initialValue || replaceValue) {
    return (
      <>
        <span id="md_editor_label" className="screen-reader-only">Create README for dataset</span>
        <div className="readme-columns-final">
          <div id="md_editor_desc">
            <p style={{marginTop: 0}}>
              To help others interpret and reuse your dataset, a README file must be included, containing
              abbreviations and codes, file descriptions, and information about any necessary software.{' '}
              <a href="/best_practices#describe-your-dataset-in-a-readme-file" target="_blank">
                <i className="far fa-file-lines" aria-hidden="true" style={{marginRight: '.5ch'}} />Learn about README files<ExitIcon />
              </a>
            </p>
            <p>
              You can copy and paste formatted text into the editor, or enter markdown by clicking the &apos;Markdown&apos; tab.
            </p>
          </div>
          <div>
            <p>You can replace the content below with a local README file in <a href="https://www.markdownguide.org/" target="_blank" rel="noreferrer">markdown format<ExitIcon /></a>, or by deleting the content and generating a new README using our tool.</p>
            <div className="readme-buttons">
              <ReadMeImport title="Import README" setValue={setReplaceValue} />
              <button
                type="button"
                className="o-button__plain-text0"
                aria-controls="restart-wizard-dialog"
                onClick={() => document.getElementById('restart-wizard-dialog').showModal()}
              >
                <i className="fa fa-trowel-bricks" aria-hidden="true" /> Generate README
              </button>
            </div>
          </div>
        </div>
        <MarkdownEditor
          id="readme_editor"
          attr={{
            'aria-errormessage': 'readme_error',
            'aria-labelledby': 'md_editor_label',
            'aria-describedby': 'md_editor_desc',
          }}
          initialValue={initialValue}
          replaceValue={replaceValue}
          onChange={checkDescription}
          onReplace={saveDescription}
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
  }
  if (wizardContent && wizardStep <= secTitles.length) {
    if (wizardStep === 0) {
      return (
        <>
          <p>
            Your Dryad submission must be accompanied by a{' '}
            <a href="/best_practices#describe-your-dataset-in-a-readme-file" target="_blank">
              README file<ExitIcon />
            </a>, to help others use and understand your
            dataset. It should contain the details needed to interpret and reuse your data, including abbreviations
            and codes, file descriptions, and information about any necessary software.
          </p>
          <p>Once you&apos;ve uploaded or generated a README, you may continue to revise it in our editor.</p>
          <div className="readme-columns">
            <div>
              <h2 className="o-heading__level2">Need to create a README?</h2>
              <p>
                Use our step-by-step tool to generate a README file.
                Some information will be imported from your uploaded files, so make sure your file list is complete.
              </p>
              <div style={{textAlign: 'center'}}>
                <button type="button" className="o-button__plain-text1" onClick={() => setWizardStep(1)}>
                  Build a README <i className="fa fa-trowel-bricks fa-flip-horizontal" aria-hidden="true" />
                </button>
              </div>
            </div>
            <div>
              <h2 className="o-heading__level2">Already have a README file?</h2>
              <p>If you already have a README file in <a href="https://commonmark.org/help/" target="_blank" rel="noreferrer">markdown format<ExitIcon /></a> for your dataset, you can import it here. </p>
              <ReadMeImport setValue={setReplaceValue} />
            </div>
          </div>
        </>
      );
    }
    return (
      <ReadMeSteps
        key={wizardStep}
        content={wizardContent}
        step={wizardStep}
        setStep={setWizardStep}
        fileList={fileList}
        restart={restartWizard}
        save={setWizardContent}
      />
    );
  }
  return (
    <p style={{display: 'flex', alignItems: 'center', gap: '.5ch'}}>
      <i className="fas fa-spin fa-spinner" aria-hidden="true" />
      Loading README generator
    </p>
  );
}

ReadMeWizard.propTypes = {
  resource: PropTypes.object.isRequired,
  setResource: PropTypes.func.isRequired,
};
