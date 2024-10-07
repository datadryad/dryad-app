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
