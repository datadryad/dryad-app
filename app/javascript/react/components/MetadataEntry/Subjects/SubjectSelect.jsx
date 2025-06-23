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
        role="listbox"
        aria-labelledby={`label_${id}`}
        aria-multiselectable="true"
        aria-describedby={`${id}-ex`}
      >
        {selected.map((subj) => (
          <span className="c-keywords__keyword" aria-selected="true" key={subj.id || subj}>
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
      {example}
    </div>
  );
}

export default SubjectSelect;
