import React from 'react';
import {render, screen} from '@testing-library/react';
import KeywordAutocomplete from '../../../../../app/javascript/react/components/MetadataEntry/KeywordAutocomplete';

describe('KeywordAutocomplete', () => {
  let info;
  beforeEach(() => {
    info = {
      name: '',
      id: '',
      saveFunction: jest.fn(),
      controlOptions: {
        htmlId: 'kwd2387', labelText: '', isRequired: false, saveOnEnter: true,
      },
    };
  });

  it('renders a basic autocomplete form', () => {
    render(<KeywordAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, {exact: false});
    expect(labeledElements.length).toBe(2);
  });
});
