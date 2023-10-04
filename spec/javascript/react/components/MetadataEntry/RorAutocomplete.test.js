import React from 'react';
import {render, screen} from '@testing-library/react';
import RorAutocomplete from '../../../../../app/javascript/react/components/MetadataEntry/RorAutocomplete';
// import acData from './rorTestData';

jest.mock('axios');

describe('RorAutocomplete', () => {
  let ac_text = '';
  let ac_id = '';
  const setAcText = (item) => { ac_text = item; };
  const setAcID = (item) => { ac_id = item; };

  beforeEach(() => {
    setAcText('Institute for Fermentation');
    setAcID('https://ror.org/05nq89q24');
  });

  it('renders the basic autocomplete form', () => {
    const info = {
      formRef: {},
      acText: ac_text,
      setAcText,
      acID: ac_id,
      setAcID,
      controlOptions: {htmlId: 'instit_affil_1234', labelText: 'Institutional affiliation', isRequired: true},
    };

    render(<RorAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, {exact: false});
    expect(labeledElements.length).toBe(2);
  });
});
