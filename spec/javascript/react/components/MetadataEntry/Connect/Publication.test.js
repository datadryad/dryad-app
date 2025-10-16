import React from 'react';
import {
  render, screen, waitFor, within,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Publication from '../../../../../../app/javascript/react/components/MetadataEntry/Connect';

jest.mock('axios');

describe('Publication', () => {
  let info; let api_journals; let journals;
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
        resource_publication: {},
        related_identifiers: [],
      },
    };
  });

  it('renders the connect section', async () => {
    axios.get.mockResolvedValue(journals);
    render(<Publication {...info} />);

    await waitFor(() => journals);
    expect(screen.getByRole(
      'group',
      {name: 'Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?'},
    )).toBeInTheDocument();
  });

  it('changes radio button and sends json request', async () => {
    const data = {status: 200, data: {import_info: 'other'}};
    axios.patch.mockResolvedValueOnce(data);

    render(<Publication {...info} />);

    const radios = screen.getByRole(
      'group',
      {name: 'Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?'},
    );
    expect(radios).toBeInTheDocument();
    expect(within(radios).getByLabelText('Yes')).not.toHaveAttribute('checked');
    expect(within(radios).getByLabelText('No')).not.toHaveAttribute('checked');

    userEvent.click(within(radios).getByLabelText('No'));

    await waitFor(() => data); // waits for the axios promise to fulfill
    expect(within(radios).getByLabelText('No').checked).toBe(true);
  });

  it('changes radio button again and displays checkboxes', async () => {
    render(<Publication {...info} />);

    const radios = screen.getByRole(
      'group',
      {name: 'Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?'},
    );
    expect(radios).toBeInTheDocument();
    expect(within(radios).getByLabelText('Yes')).not.toHaveAttribute('checked');
    expect(within(radios).getByLabelText('No')).not.toHaveAttribute('checked');

    userEvent.click(within(radios).getByLabelText('Yes'));

    const nextRadios = screen.getByRole('group', {name: 'Which would you like to connect?'});
    expect(nextRadios).toBeInTheDocument();
    expect(within(nextRadios).getByLabelText('Submitted manuscript')).not.toHaveAttribute('checked');
    expect(within(nextRadios).getByLabelText('Preprint')).not.toHaveAttribute('checked');
    expect(within(nextRadios).getByLabelText('Published article')).not.toHaveAttribute('checked');
  });
});
