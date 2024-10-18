import React from 'react';

export {default} from './Subjects';

export const keywordPass = (subjects) => {
  const keywords = subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
  const subject = subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
  if (keywords.length > 0 || !!subject) return true;
  return false;
};

export const keywordFail = (subjects, review) => {
  if (review || keywordPass(subjects)) {
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

export function SubjPreview({resource, previous}) {
  const prev = previous?.subjects.map((s) => s.subject).join(', ');
  if (resource.subjects && resource.subjects.length > 0) {
    const str = resource.subjects.map((s) => s.subject).join(', ');
    return (
      <>
        <h3 className="o-heading__level2" style={{marginBottom: '-.5rem'}}>Subject keywords</h3>
        <p>
          {previous && prev !== str ? <><ins>{str}</ins>{prev && <del>{prev}</del>}</> : str}
        </p>
      </>
    );
  }
  if (previous && previous.subjects && previous.subjects.length > 0) {
    return (
      <div className="del">
        <h3 className="o-heading__level2" style={{marginBottom: '-.5rem'}}><del>Subject keywords</del></h3>
        <p><del>{prev}</del></p>
      </div>
    );
  }
  return null;
}
