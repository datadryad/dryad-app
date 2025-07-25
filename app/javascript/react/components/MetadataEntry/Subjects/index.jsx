import React, {Fragment} from 'react';

export {default} from './Subjects';

export const keywordPass = (subjects) => {
  const keywords = subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
  const subject = subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
  if (keywords.length > 0 || !!subject) return true;
  return false;
};

export const keywordFail = (resource) => {
  const {subjects, identifier: {publication_date}} = resource;
  const pub_date = new Date(publication_date);
  const keywords = subjects.filter((s) => !['fos', 'bad_fos'].includes(s.subject_scheme));
  const subject = subjects.find((s) => ['fos', 'bad_fos'].includes(s.subject_scheme));
  if (!subject && (!publication_date || pub_date > new Date('2021-12-20'))) {
    return (
      <p className="error-text" id="domain_error">A research domain is required</p>
    );
  }
  if (keywords.length < 3 && (!publication_date || pub_date > new Date('2023-06-07'))) {
    return (
      <p className="error-text" id="subj_error">At least 3 subject keywords are required</p>
    );
  }
  return false;
};

export function SubjPreview({resource, previous}) {
  if (resource.subjects && resource.subjects.length > 0) {
    return (
      <>
        <h3 className="o-heading__level2" style={{marginBottom: '-.5rem'}}>Subjects</h3>
        <p>
          {resource.subjects.map((s, i) => {
            const prev = previous?.subjects?.[i]?.subject;
            return (
              <Fragment key={s.id}>
                {previous && prev !== s.subject ? <ins>{s.subject}</ins> : s.subject}
                {previous && prev !== s.subject && prev && <del>{prev}</del>}
                {i === resource.subjects.length - 1 ? '' : ', '}
              </Fragment>
            );
          })}
          {previous && previous.subjects.length > resource.subjects.length
            && previous.subjects.slice(resource.subjects.length).map((s) => <Fragment key={s.id}>, <del>{s.subject}</del></Fragment>)}
        </p>
      </>
    );
  }
  if (previous && previous.subjects?.length) {
    return (
      <div className="del">
        <h3 className="o-heading__level2" style={{marginBottom: '-.5rem'}}><del>Subject keywords</del></h3>
        <p><del>{previous?.subjects.map((s) => s.subject).join(', ')}</del></p>
      </div>
    );
  }
  return null;
}
