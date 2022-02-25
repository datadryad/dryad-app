import React from "react";
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event'
import RorAutocomplete from "../../../../../app/javascript/react/components/MetadataEntry/RorAutocomplete.js";
import axios from 'axios';
import {acData} from "./rorTestData"

jest.mock('axios');

describe('RorAutocomplete', () => {

  it("renders the basic autocomplete form", () => {

    const info = {name: 'Institute for Fermentation', id: 'https://ror.org/05nq89q24',
      'controlOptions': { htmlId: "instit_affil_1234", labelText: 'Institutional Affiliation', isRequired: true } }

    const { container } = render(<RorAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', info.name);

    expect(container.getElementsByClassName('js-affil-longname')[0].value).toEqual(info.name);
    expect(container.getElementsByClassName('js-affil-id')[0].value).toEqual(info.id);
  });

  it('allows changes to dd text input and resets the hidden name and ID fields after change', async () => {
    const info = {name: 'Institute for Fermentation', id: 'https://ror.org/05nq89q24',
      'controlOptions': { htmlId: "instit_affil_1234", labelText: 'Institutional Affiliation', isRequired: true } }

    /*
    // The promise stuff in here was trying to mock axios to return drop-down list, but can't get it to work for anything

    const promise = Promise.resolve({
      data: acData
    });

    axios.get.mockImplementationOnce(() => promise);
    */

    axios.get.mockResolvedValueOnce({"data": acData});

    const { container } = render(<RorAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false });

    expect(container.getElementsByClassName('js-affil-longname')[0].value).toEqual(info.name);
    expect(container.getElementsByClassName('js-affil-id')[0].value).toEqual(info.id);

    // There seems to be some kind of bug where it will not reset this value to an empty string (docs say it should)
    // also if I don't reset it then the userEvent.type below doesn't clear the previous string.

    fireEvent.change(labeledElements[0], {target: {value: 'p'}});

    fireEvent.focus(labeledElements[0]);
    await act(async () => {
      // info at: https://testing-library.com/docs/ecosystem-user-event/
      await userEvent.type(labeledElements[0], '{backspace}University of California', {delay: 20});
    });

    await waitFor(() => expect(labeledElements[0]).toHaveValue('University of California'));

    expect(container.getElementsByClassName('js-affil-longname')[0].value).toEqual('University of California');
    expect(container.getElementsByClassName('js-affil-id')[0].value).toEqual('');

    /*
    await act(() => promise);

    expect(axios.get).toHaveBeenCalled();
    await waitFor(() => {
      expect(getByText('University of California, Irvine').toBeInTheDocument());
    });
    */
  });
});