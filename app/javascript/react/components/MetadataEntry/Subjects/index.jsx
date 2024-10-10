import React from 'react';

export {default} from './Subjects';

export const keywordPass = (subjects) => {
  const keywords = subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
  const subject = subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
  if (keywords.length > 0 || !!subject) return true;
  return false;
};

export const keywordFail = (subjects) => {
  if (keywordPass(subjects)) {
    const keywords = subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
    const subject = subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
    if (keywords.length < 3) {
      return (
        <p className="error-text" id="subj_error">At least 3 keywords are required</p>
      );
    }
    if (!subject) {
      return (
        <p className="error-text" id="domain_error">A research domain is required</p>
      );
    }
  }
  return false;
};

export function SubjPreview({resource}) {
  if (resource.subjects && resource.subjects.length > 0) {
    return (
      <>
        <h3 className="o-heading__level2" style={{marginBottom: '-.5rem'}}>Subject keywords</h3>
        <p>{resource.subjects.map((s) => s.subject).join(', ')}</p>
      </>
    );
  }
}
