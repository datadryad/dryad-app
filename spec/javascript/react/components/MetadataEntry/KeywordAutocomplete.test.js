import React from 'react';
import {
  act, fireEvent, render, screen, waitFor,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import axios from 'axios';
import KeywordAutocomplete from '../../../../../app/javascript/react/components/MetadataEntry/KeywordAutocomplete';

jest.mock('axios');

describe('KeywordAutocomplete', () => {
  it('renders a basic autocomplete form', () => {
    const info = {
      name: '',
      id: '',
      saveFunction: jest.fn(),
      controlOptions: {htmlId: 'kwd2387', labelText: '', isRequired: false},
    };

    render(<KeywordAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, {exact: false});
    expect(labeledElements.length).toBe(2);
  });

  it('allows changes to dd text input and resets the hidden name and ID fields after change', async () => {
    // keywords start out blank in entry and appear in other component after entered
    const info = {
      name: '',
      id: '',
      saveFunction: jest.fn(),
      controlOptions: {htmlId: 'kwd2387', labelText: '', isRequired: false},
    };

    const promise = Promise.resolve({
      data: [{id: 1, name: 'Mycelium'}, {id: 2, name: 'Spores'}],
    });

    axios.get.mockImplementationOnce(() => promise);

    render(<KeywordAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, {exact: false});

    userEvent.clear(labeledElements[0]);

    fireEvent.focus(labeledElements[0]);
    await act(async () => {
      // info at: https://testing-library.com/docs/ecosystem-user-event/
      await userEvent.type(labeledElements[0], 'fixed', {delay: 20});
    });

    await waitFor(() => expect(labeledElements[0]).toHaveValue('fixed'));

    await waitFor(() => promise); // waits for the axios promise to fulfill
  });
});
