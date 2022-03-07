import React from "react";
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import FunderAutocomplete from "../../../../../app/javascript/react/components/MetadataEntry/FunderAutocomplete.js";
import axios from 'axios';

jest.mock('axios');

describe('FunderAutocomplete', () => {
  /* react_component('components/MetadataEntry/FacilityAutocomplete',
		<%= react_component('components/MetadataEntry/FunderAutocomplete',
												{name: (contributor&.contributor_name || ''),
												 id: (contributor&.name_identifier_id || ''),
												 'controlOptions': { 'htmlId' => "contrib_#{my_suffix}", 'labelText' => 'Granting Organization', 'isRequired' => false }
												}) %>
}) */
  it("renders the basic autocomplete form", () => {

    const info = {name: 'Terra Viva Grants', id: 'http://dx.doi.org/10.13039/100004456',
      'controlOptions': { 'htmlId': "contrib_1", 'labelText': 'Granting Organization', 'isRequired': false } }

    const { container } = render(<FunderAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', info.name);

    expect(container.getElementsByClassName('js-funder-longname')[0].value).toEqual(info.name);
    expect(container.getElementsByClassName('js-funder-id')[0].value).toEqual(info.id);
  });

  it('allows changes to dd text input', async () => {
    const info = {name: 'Terra Viva Grants', id: 'http://dx.doi.org/10.13039/100004456',
      'controlOptions': { 'htmlId': "contrib_1", 'labelText': 'Granting Organization', 'isRequired': false } }

    // axios.get.mockResolvedValueOnce({"data": acData});

    const { container } = render(<FunderAutocomplete {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false });


    // There seems to be some kind of bug where it will not reset this value to an empty string (docs say it should)
    // also if I don't reset it then the userEvent.type below doesn't clear the previous string.

    fireEvent.change(labeledElements[0], {target: {value: 'p'}});

    fireEvent.focus(labeledElements[0]);
    await act(async () => {
      // info at: https://testing-library.com/docs/ecosystem-user-event/
      await userEvent.type(labeledElements[0], '{backspace}Crow Granting', {delay: 20});
    });

    await waitFor(() => expect(labeledElements[0]).toHaveValue('Crow Granting'));
  });
});