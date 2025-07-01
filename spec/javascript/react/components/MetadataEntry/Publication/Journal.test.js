import React from 'react';
import {render, screen} from '@testing-library/react';
import Journal from '../../../../../../app/javascript/react/components/MetadataEntry/Publication/Journal';

describe('Journal', () => {
  let formRef; let title; let setTitle; let issn; let setIssn; let setAPIJournal;
  let info;
  beforeEach(() => {
    [title, setTitle] = ['Nature Conservation', (i) => { title = i; }];
    [issn, setIssn] = ['1314-6947', (i) => { issn = i; }];
    formRef = {};
    setAPIJournal = () => {};
    info = {
      current: true,
      formRef,
      title,
      setTitle,
      issn,
      setIssn,
      setAPIJournal,
      controlOptions: {
        htmlId: 'publication',
        labelText: 'Journal name',
        isRequired: true,
      },
    };
  });

  it('renders the basic autocomplete form for Journal name', () => {
    /* mocks for use/set state, these don't really do the functionality, but just give dummy objects */

    render(<Journal {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText);
    expect(labeledElements.length).toBe(1);
    expect(labeledElements[0]).toHaveAttribute('value', title);
  });
});
