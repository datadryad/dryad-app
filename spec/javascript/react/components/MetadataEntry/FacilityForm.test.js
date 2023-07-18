import React from "react";
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event'
import FacilityForm from "../../../../../app/javascript/react/components/MetadataEntry/FacilityForm";
import axios from 'axios';
import {acData} from "./rorTestData"

jest.mock('axios');

describe('FacilityForm', () => {

  it("renders the basic autocomplete form under facility", () => {

    const info = {name: 'Friends of Karen', rorId: 'https://ror.org/02rrdqs77',
      contribId: null, resourceId: 123, createPath: '/create_path', updatePath: 'update_path',
      'controlOptions': { htmlId: "research_facility", labelText: 'Research facility', isRequired: false } }

    const { container } = render(<FacilityForm {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', info.name);
  });

  it('allows changes to dd text input', async () => {
    const info = {name: 'Friends of Karen', rorId: 'https://ror.org/02rrdqs77',
      contribId: null, resourceId: 123, createPath: '/create_path', updatePath: 'update_path',
      'controlOptions': { htmlId: "research_facility", labelText: 'Research facility', isRequired: false } }

    /*
    // The promise stuff in here was trying to mock axios to return drop-down list, but can't get it to work for anything

    const promise = Promise.resolve({
      data: acData
    });

    axios.get.mockImplementationOnce(() => promise);
    */

    axios.get.mockResolvedValueOnce({"data": acData});

    const { container } = render(<FacilityForm {...info} />)

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false });

    const inputEl = container.querySelector('input#research_facility');

    expect(inputEl.value).toEqual(info.name);

    // There seems to be some kind of bug where it will not reset this value to an empty string (docs say it should)
    // also if I don't reset it then the userEvent.type below doesn't clear the previous string.

    fireEvent.change(inputEl, {target: {value: 'p'}});

    fireEvent.focus(labeledElements[0]);
    await act(async () => {
      // info at: https://testing-library.com/docs/ecosystem-user-event/
      await userEvent.type(inputEl, '{backspace}University of California', {delay: 20});
    });

    await waitFor(() => expect(inputEl).toHaveValue('University of California'));

    expect(inputEl.value).toEqual('University of California');
  });
});