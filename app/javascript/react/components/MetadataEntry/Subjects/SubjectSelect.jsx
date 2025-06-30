import React from 'react';

function SubjectSelect({
  selected, id, label, example, remove, children,
}) {
  return (
    <div className="c-keywords">
      <label className="input__label required" id={`label_${id}`} htmlFor={id}>
        {label}
      </label>
      <div
        className="c-keywords__container"
      >
        {selected.map((subj) => (
          <span className="c-keywords__keyword" key={subj.id || subj}>
            {subj.subject || subj}
            <span className="delete_keyword">
              <button
                id={`sub_remove_${subj.id || subj.replace(/ /g, '_')}`}
                aria-label={`Remove keyword ${subj.subject || subj}`}
                title="Remove"
                type="button"
                className="c-keywords__keyword-remove"
                onClick={() => remove(subj.id || subj)}
              >
                <i className="fas fa-times" aria-hidden="true" />
              </button>
            </span>
          </span>
        ))}
        {children}
      </div>
      <div className="screen-reader-only" role="status">Selected: {selected.map((s) => s.subject || s).join(', ')}</div>
      {example}
    </div>
  );
}

export default SubjectSelect;
