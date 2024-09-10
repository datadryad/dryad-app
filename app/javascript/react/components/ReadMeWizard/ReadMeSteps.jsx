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
        <p>Provide a comprehensive list of data files and variables. Starting information has been imported from your uploaded files.</p>
        <ul>
          <li>Add any folders and data files inside compressed archives (.zip, .gz), and any missing variables</li>
          <li>Describe files and define all variables and abbreviations used, including units of measurement</li>
          <li>List how you indicate missing values (blank cells, &quot;NA&quot;, etc.) if applicable</li>
        </ul>
      </>,
      content: content.step2 || formatList(fileList),
      examples: [
        {
          key: 'nzs7h44xg',
          example:
        <><a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.nzs7h44xg#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />View example README<span className="screen-reader-only"> (opens in new window)</span></a> describing data of several file types, including genomic data
        </>,
        },
        {
          key: 'rr4xgxdg6',
          example:
        <><a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.rr4xgxdg6#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />View example README<span className="screen-reader-only"> (opens in new window)</span></a> with a content section describing MATLAB files
        </>,
        },
        {
          key: '18931zd25',
          example:
        <><a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.18931zd25#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />View example README<span className="screen-reader-only"> (opens in new window)</span></a> with good detail for genomic VCF files
        </>,
        },
      ],
    },
    3: {
      desc: <p>What free or open software is needed to view your data? Describe the software, including versions and loaded packages that you used to run files, and the workflow that you used if the relationship of files to software is not clear. If code or scripts are included with your submission, describe them here.</p>,
      content: content.step3 || '',
      examples: [
        {
          key: 'jdfn2z3j3',
          example:
        <><a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.jdfn2z3j3#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />View example README<span className="screen-reader-only"> (opens in new window)</span></a> containing excellent information on how to set up, access, and run neural network deep learning code
        </>,
        },
        {
          key: 'h70rxwdq5',
          example:
        <><a href="https://datadryad.org/stash/dataset/doi:10.5061/dryad.h70rxwdq5#readme" target="_blank" rel="noreferrer"><i className="fa fa-right-to-bracket" aria-hidden="true" />View example README<span className="screen-reader-only"> (opens in new window)</span></a> with a detailed Recommended Software section
        </>,
        },
      ],
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
          /* eslint-disable-next-line eqeqeq */
          <div key={`step${i}`} className={`step${i < step ? ' completed' : ''}${i == step ? ' current' : ''}`} aria-current={step == i}>
            <span className="step-counter">{i}</span><span className="step-name">{secTitles[i - 1]}</span>
          </div>
        ))}
      </div>
      <h2><label htmlFor="readme_step_editor">{secTitles[step - 1]}</label></h2>
      {Object.hasOwn(sections[step], 'examples') ? (
        <div className="readme-columns-final">
          <div>{sections[step].desc}</div>
          <div style={{padding: '1.5rem'}}>
            <ul className="readme-examples">
              {sections[step].examples.map((ex) => <li key={ex.key}>{ex.example}</li>)}
            </ul>
          </div>
        </div>
      ) : (
        <div>{sections[step].desc}</div>
      )}
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
