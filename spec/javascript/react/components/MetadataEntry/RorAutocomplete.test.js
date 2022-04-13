import React from "react";
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event'
import RorAutocomplete from "../../../../../app/javascript/react/components/MetadataEntry/RorAutocomplete.js";
import axios from 'axios';
import {acData} from "./rorTestData"

jest.mock('axios');

describe('RorAutocomplete', () => {

  let ac_text, ac_id;
  const acText = () => ac_text;
  const acID = () => ac_id;
  const setAcText = (item) => { ac_text = item };
  const setAcID = (item) => { ac_id = item };

  beforeEach(() => {
    setAcText('Institute for Fermentation');
    setAcID('https://ror.org/05nq89q24');
  });

  it("renders the basic autocomplete form", () => {

    const info = {formRef: null, acText: acText, setAcText: setAcText, acID: acID, setAcID,
      'controlOptions': { htmlId: "instit_affil_1234", labelText: 'Institutional Affiliation', isRequired: true } }

    const { container } = render(<RorAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
  });

});