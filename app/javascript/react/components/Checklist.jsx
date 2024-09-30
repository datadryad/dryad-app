import React from 'react';

export default function Checklist({
  steps, step, setStep, open, setOpen,
}) {
  return (
    <nav id="submission-nav" className={(open && 'open') || (step.name === 'Start' && 'start') || ''}>
      <div>
        {step.name !== 'Start' && (
          <button
            type="button"
            id="checklist-button"
            aria-label="View checklist"
            aria-haspopup="menu"
            aria-controls="submission-checklist"
            aria-expanded={open}
            onClick={() => setOpen(!open)}
          >
            <i className="fas fa-list-check" aria-hidden="true" />
          </button>
        )}
        <ul id="submission-checklist" hidden={!open && step.name !== 'Start'}>
          {steps.map((s) => (
            <li
              key={s.name}
              aria-current={step.name === s.name ? 'step' : null}
              aria-describedby={(s.fail && 'step-error') || (s.pass && 'step-complete') || 'step-todo'}
            >
              <button type="button" className="checklist-link" onClick={() => setStep(s)}>
                <span className="checklist-icon">
                  <i className="fas fa-square" aria-hidden="true" />
                  <i className="far fa-square" aria-hidden="true" />
                  {(s.pass || s.fail) && <i className={`fas fa-${s.fail ? 'xmark' : 'check'}`} aria-hidden="true" />}
                </span>{s.name}
              </button>
            </li>
          ))}
        </ul>
        <span id="step-todo" className="screen-reader-only">Submission step awaiting completion</span>
        <span id="step-complete" className="screen-reader-only">Completed submission step</span>
        <span id="step-error" className="screen-reader-only">Submission step has errors</span>
      </div>
    </nav>
  );
}
