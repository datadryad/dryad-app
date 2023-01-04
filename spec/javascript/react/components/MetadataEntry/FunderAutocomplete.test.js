import React from "react";
import {render, screen} from '@testing-library/react';
import FunderAutocomplete from "../../../../../app/javascript/react/components/MetadataEntry/FunderAutocomplete";
// import axios from 'axios';

// jest.mock('axios');

describe('FunderAutocomplete', () => {

  let acText, setAcText, acID, setAcID, formRef, info, groupings;
  beforeEach(() => {
    [acText, setAcText] = ['Terra Viva Grants', (i) => { acText = i } ];
    [acID, setAcID] = ['http://dx.doi.org/10.13039/100004456', (i) => { acID = i }]
    formRef = {};
    groupings = [];

    info = {formRef, acText, setAcText, acID, setAcID, groupings,
      'controlOptions': { 'htmlId': "contrib_1", 'labelText': 'Granting Organization', 'isRequired': false } }
  });

  it("renders the basic autocomplete form", () => {
    /* mocks for use/set state, these don't really do the functionality, but just give dummy objects */

    const { container } = render(<FunderAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', acText);
  });
});