import React from 'react';
import {upCase} from '../../../../lib/utils';

export default function Editor({editor}) {
  return (
    <>
      {editor && editor.role && (
        <div className="author-one-line" style={{marginLeft: 'auto'}}>
          <i className={`fas fa-user-${['creator', 'submitter'].includes(editor.role) ? 'tag' : 'pen'}`} aria-hidden="true" />&nbsp;
          {upCase(editor.role)}
        </div>
      )}
      <div />
    </>
  );
}
