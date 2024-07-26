/* eslint-disable max-len */
import React from 'react';
import MarkdownEditor from '../MarkdownEditor';

const formatList = (fileList) => fileList.map((f) => `#### File: ${f.name}\n**Description:**&nbsp;\n\n##### Variables\n${f.variables.map((v) => `* ${v}: `).join('\n')}`).join('\n\n');

export const secTitles = ['Data description', 'Files and variables', 'Code/software', 'Access information'];

export default function ReadMeSteps({
  step, setStep, content, fileList, save,
}) {
  const saveContent = (markdown) => {
    if (markdown.trim()) {
      content[`step${step}`] = markdown;
    } else {
      delete content[`step${step}`];
    }
    save(JSON.stringify(content));
  };

  const sections = {
    1: {
      desc: 'Provide a short description of the experimental efforts for which the data was collected.',
      content: content.step1 || '',
    },
    2: {
      desc: 'Provide a comprehensive list of data files, and define all variables and abbreviations used, including units of measurement. List how you indicate missing values (blank cells, "NA", etc.) if applicable. Please add descriptions below, and add any folders and files inside compressed archives (.zip, .gz) to the list. ',
      content: content.step2 || formatList(fileList),
    },
    3: {
      desc: 'What free or open software is needed to view your data? Describe the code software, including versions and loaded packages that you used to run files, and the workflow that you used if the relationship of files to software is not clear. If code or scripts are included with your submission, describe them here.',
      content: content.step3 || '',
    },
    4: {
      desc: 'If applicable, provide links to other publicly accessible locations of the data. If your data was derived from another source(s), list the source(s) and include license information.',
      content: content.step5 || 'Other publicly accessible locations of the data:\n\n* \n\nData was derived from the following sources:\n\n* ',
    },
  };

  return (
    <>
      <div className="steps-wrapper">
        {Object.keys(sections).map((i) => (
          /* eslint-disable-next-line eqeqeq */
          <div key={`step${i}`} className={`step${i < step ? ' completed' : ''}${i == step ? ' current' : ''}`} aria-current={step == i}>
            <span className="step-counter">{i}</span><span className="step-name">{secTitles[i - 1]}</span>
          </div>
        ))}
      </div>
      <h2><label htmlFor="readme_step_editor">{secTitles[step - 1]}</label></h2>
      <p>{sections[step].desc}</p>
      <MarkdownEditor
        id="readme_step_editor"
        {...(step === 1 ? {initialValue: '', replaceValue: sections[step].content} : {initialValue: sections[step].content})}
        onChange={saveContent}
      />
      <div className="o-dataset-nav" style={{marginBottom: '4rem'}}>
        <button type="button" className="o-button__plain-text" onClick={() => setStep(step - 1)}>
          <i className="fa fa-caret-left" aria-hidden="true" /> Previous
        </button>
        <button type="button" className="o-button__plain-text2" onClick={() => setStep(step + 1)}>
          {step === secTitles.length ? (
            <>Complete &amp; generate README</>
          ) : (
            <>Next <i className="fa fa-caret-right" aria-hidden="true" /></>
          )}
        </button>
      </div>
    </>
  );
}
