import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import TitleImport from '../../../../../../app/javascript/react/components/MetadataEntry/Title';

jest.mock('axios');

describe('TitleImport', () => {
  let info; let api_journals; let api; let journals; let update; let primary_article; let related_identifiers;
  const setResource = () => {};

  beforeEach(() => {
    const makeIssn = () => `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`;
    api_journals = (new Array(3).fill(null)).map(() => makeIssn());
    journals = {data: {api_journals}};
    info = {
      current: true,
      setResource,
      resource: {
        id: faker.datatype.number(),
        identifier: {
          import_type: 'other',
        },
        resource_type: {resource_type: 'dataset'},
        resource_publication: {
          publication_name: faker.company.companyName(),
          publication_issn: `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`,
          manuscript_number: 'TEST-MAN-0001',
        },
        related_identifiers: [],
      },
    };
    primary_article = 'https://doi.org/10.111/Adahdjshf';
    related_identifiers = [{
      related_identifier: primary_article,
      work_type: 'primary_article',
    }];
    api = {data: {api_journals}};
    update = {
      status: 200,
      data: {
        journal: null,
        resource_publication: info.resource.resource_publication,
        related_identifiers,
      },
    };
  });

  it('renders the import suggestion section', async () => {
    axios.get.mockResolvedValue(journals);
    render(<TitleImport {...info} />);

    await waitFor(() => journals);
    expect(
      screen.getByText('The title and other metadata can sometimes be imported. Choose a source and click the button to import'),
    ).toBeInTheDocument();
    expect(screen.getByText('TEST-MAN-0001')).toBeInTheDocument();
    expect(screen.getByText('Import metadata')).toBeInTheDocument();
  });

  it('checks that clicking button triggers axios save', async () => {
    axios.get.mockResolvedValueOnce(api);
    axios.patch.mockResolvedValueOnce(update);
    render(<TitleImport {...info} />);

    userEvent.click(screen.getByText('Import metadata'));
    await waitFor(() => update); // waits for the axios promise to fulfil
  });
});
