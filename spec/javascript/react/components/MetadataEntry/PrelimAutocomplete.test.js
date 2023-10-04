import React from 'react';
import {render, screen} from '@testing-library/react';
import PrelimAutocomplete from '../../../../../app/javascript/react/components/MetadataEntry/PrelimAutocomplete';
// import axios from 'axios';

// jest.mock('axios');

describe('PrelimAutocomplete', () => {
  // very similar to the rest of the autocompletes

  let acText; let setAcText; let acID; let setAcID; let formRef; let
    info;
  beforeEach(() => {
    [acText, setAcText] = ['Nature Conservation', (i) => { acText = i; }];
    [acID, setAcID] = ['1314-6947', (i) => { acID = i; }];
    formRef = {};

    info = {
      formRef,
      acText,
      setAcText,
      acID,
      setAcID,
      controlOptions: {
        htmlId: 'publication',
        labelText: 'Journal name',
        isRequired: true,
      },
    };
  });

  it('renders the basic autocomplete form for Journal name', () => {
    /* mocks for use/set state, these don't really do the functionality, but just give dummy objects */

    render(<PrelimAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, {exact: false});
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', acText);
  });
});
