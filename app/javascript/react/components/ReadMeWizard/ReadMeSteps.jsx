/* eslint-disable max-len */
import React from 'react';
import MarkdownEditor from '../MarkdownEditor';

const formatList = (fileList) => fileList.map((f) => {
  let l = `#### File: ${f.name}\n**Description:**&nbsp;\n\n`;
  if (Object.hasOwn(f, 'variables')) {
    l += `##### Variables\n${f.variables.length === 0 ? '* \n' : f.variables.map((v) => `* ${v}: `).join('\n')}`;
  }
  return l;
}).join('\n\n');

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
      desc: <p>Provide a short description of the experimental efforts for which the data was collected.</p>,
      content: content.step1 || '',
    },
    2: {
      desc:
      <>
        <p style={{marginBottom: 0}}>Provide a comprehensive list of data files and variables. Starting information has been imported from your uploaded files.</p>
        <ul>
          <li>Add any folders and data files inside compressed archives (.zip, .gz), and any missing variables</li>
          <li>Describe files and define all variables and abbreviations used, including units of measurement</li>
          <li>List how you indicate missing values (blank cells, &quot;NA&quot;, etc.) if applicable</li>
        </ul>
      </>,
      content: content.step2 || formatList(fileList),
    },
    3: {
      desc: <p>What free or open software is needed to view your data? Describe the software, including versions and loaded packages that you used to run files, and the workflow that you used if the relationship of files to software is not clear. If code or scripts are included with your submission, describe them here.</p>,
      content: content.step3 || '',
    },
    4: {
      desc: <p>If applicable, provide links to other publicly accessible locations of the data. If your data was derived from another source(s), list the source(s) and include license information.</p>,
      content: content.step5 || 'Other publicly accessible locations of the data:\n\n* \n\nData was derived from the following sources:\n\n* ',
    },
  };

  return (
    <>
      <div className="steps-wrapper">
        {Object.keys(sections).map((i) => (
          /* eslint-disable eqeqeq */
          <div
            key={`step${i}`}
            className={`step${i < step ? ' completed' : ''}${i == step ? ' current' : ''}`}
            aria-current={step == i ? 'step' : null}
            role="button"
            tabIndex={0}
            onClick={() => setStep(i)}
            onKeyDown={(e) => {
              if (['Enter', 'Space'].includes(e.key)) {
                setStep(i);
              }
            }}
          >
            <span className="bar" /><span className="step-counter">{i}</span><span className="step-name">{secTitles[i - 1]}</span>
          </div>
        ))}
      </div>
      <h3 id="md_editor_label">{secTitles[step - 1]}</h3>
      <div style={{margin: '-.5em 0'}} id="md_editor_desc">
        {sections[step].desc}
      </div>
      <MarkdownEditor
        id="readme_step_editor"
        {...(step === 1 ? {initialValue: '', replaceValue: sections[step].content} : {initialValue: sections[step].content})}
        onChange={saveContent}
      />
      <div className="o-dataset-nav" style={{marginTop: '2rem', marginBottom: '2rem'}}>
        <button type="button" className="o-button__plain-text1" onClick={() => setStep(step + 1)}>
          {step === secTitles.length ? (
            <>Complete &amp; generate README</>
          ) : (
            <>Next <i className="fa fa-caret-right" aria-hidden="true" /></>
          )}
        </button>
        {step > 1 && (
          <button type="button" className="o-button__plain-text0" onClick={() => setStep(step - 1)}>
            <i className="fa fa-caret-left" aria-hidden="true" /> Previous
          </button>
        )}
      </div>
    </>
  );
}
