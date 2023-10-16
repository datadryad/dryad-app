import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import FacilityForm from '../../../../../app/javascript/react/components/MetadataEntry/FacilityForm';

jest.mock('axios');

describe('FacilityForm', () => {
  let info;

  beforeEach(() => {
    info = {
      name: '',
      rorId: '',
      contribId: faker.datatype.number(),
      resourceId: 123,
      createPath: faker.system.directoryPath(),
      updatePath: faker.system.directoryPath(),
      controlOptions: {htmlId: 'research_facility', labelText: 'Research facility', isRequired: false},
    };
  });

  it('renders the basic autocomplete form under facility', () => {
    render(<FacilityForm {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, {exact: false});
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', info.name);
  });

  it('selects from autocomplete options shown while typing', async () => {
    const options = Promise.resolve({
      status: 200,
      data: [
        {
          id: 'https://ror.org/00x6h5n95', name: 'Dryad Digital Repository', country: 'United States', acronyms: [],
        },
        {
          id: 'https://ror.org/006zwes74', name: 'Dryas Arqueologia (Portugal)', country: 'Portugal', acronyms: [],
        },
      ],
    });

    axios.get.mockImplementationOnce(() => options);

    const dryad = {
      id: info.contribId,
      contributor_name: 'Dryad Digital Repository',
      contributor_type: 'sponsor',
      identifier_type: 'ror',
      name_identifier_id: 'https://ror.org/00x6h5n95',
      resourceId: 123,
    };

    axios.mockResolvedValueOnce({status: 200, data: dryad});

    render(<FacilityForm {...info} />);

    const input = screen.getByLabelText('Research facility:', {exact: true});

    userEvent.clear(input);
    userEvent.type(input, 'Drya');

    await waitFor(() => options);

    const menu = screen.getByLabelText('Research facility autocomplete list');
    expect(menu).toBeVisible();

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(2));

    userEvent.selectOptions(menu, screen.getByText(/Dryad Digital Repository/));

    await waitFor(() => Promise.resolve());

    expect(input).toHaveAttribute('value', dryad.contributor_name);
  });
});
