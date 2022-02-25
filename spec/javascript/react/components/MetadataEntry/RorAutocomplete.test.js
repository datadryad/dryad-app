import React from "react";
import {act, fireEvent, render, screen} from '@testing-library/react';
import RorAutocomplete from "../../../../../app/javascript/react/components/MetadataEntry/RorAutocomplete.js";
import axios from 'axios';

describe('RorAutocomplete', () => {

  const acData =
  {
    "number_of_results": 3333,
    "time_taken": 17,
    "items": [
      {
        "id": "https://ror.org/04gyf1771",
        "name": "University of California, Irvine"
      },
      {
        "id": "https://ror.org/00d9ah105",
        "name": "University of California, Merced"
      },
      {
        "id": "https://ror.org/05rrcem69",
        "name": "University of California, Davis"
      },
      {
        "id": "https://ror.org/056d3gw71",
        "name": "Dominican University of California"
      },
      {
        "id": "https://ror.org/03taz7m60",
        "name": "University of Southern California"
      },
      {
        "id": "https://ror.org/01an7q238",
        "name": "University of California, Berkeley"
      },
      {
        "id": "https://ror.org/00pjdza24",
        "name": "University of California System"
      }
    ]
  };

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

  it('should return list of institutions in dropdown', async () => {
    const info = {name: '', id: '',
      'controlOptions': { htmlId: "instit_affil_1234", labelText: 'Institutional Affiliation', isRequired: true } }

    const promise = Promise.resolve({
      data: acData
    })

    jest.mock('axios');

    axios.get.mockImplementationOnce(() => promise);

    const { container } = render(<RorAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })

    screen.debug();

    fireEvent.change(labeledElements[0], {target: {value: 'University of California'}});

    await act(() => promise);

    screen.debug();
  });

  it('should select institution from dropdown and fill hidden fields', () => {
  });
});