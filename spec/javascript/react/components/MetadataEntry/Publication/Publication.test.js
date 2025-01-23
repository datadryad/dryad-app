import React from 'react';
import {
  render, screen, waitFor, within,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Publication from '../../../../../../app/javascript/react/components/MetadataEntry/Publication';

jest.mock('axios');

describe('Publication', () => {
  let info; let api_journals; let journals;
  const setResource = () => {};

  beforeEach(() => {
    const makeIssn = () => `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`;
    api_journals = (new Array(3).fill(null)).map(() => makeIssn());
    journals = {data: {api_journals}};
    info = {
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
          manuscript_number: '',
        },
        related_identifiers: [],
      },
    };
  });

  it('renders the preliminary information section', async () => {
    axios.get.mockResolvedValue(journals);
    render(<Publication {...info} />);

    await waitFor(() => journals);
    expect(screen.getByRole('group', {name: 'Is your data used in a published article, with a DOI?'})).toBeInTheDocument();
  });

  it('changes radio button and sends json request', async () => {
    const data = {status: 200, data: {import_info: 'published'}};
    axios.patch.mockResolvedValueOnce(data);

    render(<Publication {...info} />);

    const radios = screen.getByRole('group', {name: 'Is your data used in a published article, with a DOI?'});
    expect(radios).toBeInTheDocument();
    expect(within(radios).getByLabelText('Yes')).not.toHaveAttribute('checked');
    expect(within(radios).getByLabelText('No')).not.toHaveAttribute('checked');

    userEvent.click(within(radios).getByLabelText('Yes'));

    await waitFor(() => data); // waits for the axios promise to fulfill
    expect(within(radios).getByLabelText('Yes').checked).toBe(true);
  });

  it('changes radio button again and sends json request', async () => {
    const first = {status: 200, data: {import_info: 'other'}};
    axios.patch.mockResolvedValueOnce(first);
    const data = {status: 200, data: {import_info: 'manuscript'}};
    axios.patch.mockResolvedValueOnce(data);

    render(<Publication {...info} />);

    const radios = screen.getByRole('group', {name: 'Is your data used in a published article, with a DOI?'});
    expect(radios).toBeInTheDocument();
    expect(within(radios).getByLabelText('Yes')).not.toHaveAttribute('checked');
    expect(within(radios).getByLabelText('No')).not.toHaveAttribute('checked');

    userEvent.click(within(radios).getByLabelText('No'));
    await waitFor(() => first);

    const nextRadios = screen.getByRole('group', {name: 'Is your data used in a submitted manuscript, with a manuscript number?'});
    expect(nextRadios).toBeInTheDocument();
    expect(within(nextRadios).getByLabelText('Yes')).not.toHaveAttribute('checked');
    expect(within(nextRadios).getByLabelText('No')).not.toHaveAttribute('checked');

    userEvent.click(within(nextRadios).getByLabelText('Yes'));

    await waitFor(() => data); // waits for the axios promise to fulfill
    expect(within(nextRadios).getByLabelText('Yes').checked).toBe(true);
  });

  it('changes radio button and sends failed json request', async () => {
    const data = {status: 400};
    axios.patch.mockResolvedValueOnce(data);

    render(<Publication {...info} />);

    const radios = screen.getByRole('group', {name: 'Is your data used in a published article, with a DOI?'});
    expect(radios).toBeInTheDocument();
    expect(within(radios).getByLabelText('Yes')).not.toHaveAttribute('checked');
    expect(within(radios).getByLabelText('No')).not.toHaveAttribute('checked');

    userEvent.click(within(radios).getByLabelText('Yes'));

    await waitFor(() => data); // waits for the axios promise to fulfill
  });
});
