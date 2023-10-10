import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import PrelimInfo from '../../../../../app/javascript/react/components/MetadataEntry/PrelimInfo';
import journals from './prelimjournals.json';

jest.mock('axios');

describe('PrelimInfo', () => {
  let info;

  beforeEach(() => {
    const identifierId = faker.datatype.number();
    info = {
      resourceId: faker.datatype.number(),
      identifierId,
      publication_name: {
        id: faker.datatype.number(),
        identifier_id: identifierId,
        data_type: 'publicationName',
        value: faker.company.companyName(),
      },
      publication_issn: {
        id: faker.datatype.number(),
        identifier_id: identifierId,
        data_type: 'publicationISSN',
        value: `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`,
      },
      msid: {
        id: faker.datatype.number(),
        identifier_id: identifierId,
        data_type: 'manuscriptNumber',
        value: '',
      },
      related_identifier: '',
    };
  });

  it('renders the preliminary information section', () => {
    render(<PrelimInfo importInfo="other" {...info} />);

    expect(screen.getByLabelText('a manuscript in progress')).toBeInTheDocument();
    expect(screen.getByLabelText('a published article')).toBeInTheDocument();
    expect(screen.getByLabelText('other or not applicable')).toBeInTheDocument();
  });

  it('changes radio button and sends json request', async () => {
    const promise = Promise.resolve({status: 200, data: {import_info: 'published'}});

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimInfo importInfo="other" {...info} />);

    expect(screen.getByLabelText('other or not applicable')).toHaveAttribute('checked');
    expect(screen.getByLabelText('a published article')).not.toHaveAttribute('checked');

    userEvent.click(screen.getByLabelText('a published article'));

    await waitFor(() => promise); // waits for the axios promise to fulfill
    expect(screen.getByLabelText('a published article').checked).toBe(true);
  });

  it('changes radio button again and sends json request', async () => {
    const promise = Promise.resolve({status: 200, data: {import_info: 'manuscript'}});

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimInfo importInfo="published" {...info} />);

    expect(screen.getByLabelText('a published article')).toHaveAttribute('checked');
    expect(screen.getByLabelText('a manuscript in progress')).not.toHaveAttribute('checked');

    userEvent.click(screen.getByLabelText('a manuscript in progress'));
    expect(screen.getByLabelText('a manuscript in progress').checked).toBe(true);

    await waitFor(() => promise); // waits for the axios promise to fulfill
  });

  it('changes radio button and sends failed json request', async () => {
    const promise = Promise.resolve({status: 400});

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimInfo importInfo="manuscript" {...info} />);

    expect(screen.getByLabelText('other or not applicable')).not.toHaveAttribute('checked');
    expect(screen.getByLabelText('a manuscript in progress')).toHaveAttribute('checked');

    userEvent.click(screen.getByLabelText('other or not applicable'));
    expect(screen.getByLabelText('other or not applicable').checked).toBe(true);

    await waitFor(() => promise); // waits for the axios promise to fulfill
  });

  it('selects from journal autocomplete options shown while typing', async () => {
    const options = Promise.resolve({status: 200, data: journals});
    axios.get.mockImplementationOnce(() => options);

    render(<PrelimInfo importInfo="published" {...info} />);

    const input = screen.getByLabelText('Journal name:', {exact: true});

    userEvent.clear(input);
    userEvent.type(input, 'PLOS');

    await waitFor(() => options);

    const data = {error: null, reloadPage: false};
    const promise = Promise.resolve({status: 200, data});
    axios.patch.mockImplementationOnce(() => promise);

    const menu = screen.getByLabelText('Journal name autocomplete list');
    expect(menu).toBeVisible();

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(8));

    userEvent.selectOptions(menu, 'PLOS ONE');

    await waitFor(() => promise);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', 'PLOS ONE');
    });
  });

  it('saves journal that matches an autocomplete option', async () => {
    const options = Promise.resolve({status: 200, data: journals});
    axios.get.mockImplementationOnce(() => options);

    render(<PrelimInfo importInfo="published" {...info} />);

    const input = screen.getByLabelText('Journal name:', {exact: true});

    userEvent.clear(input);
    userEvent.type(input, 'PLOS ONE');

    await waitFor(() => options);

    const data = {error: null, reloadPage: false};
    const promise = Promise.resolve({status: 200, data});
    axios.patch.mockImplementationOnce(() => promise);

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(8));

    userEvent.tab();

    await waitFor(() => promise);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', 'PLOS ONE');
    });
  });

  it('saves text that does not match an autocomplete option', async () => {
    const options = Promise.resolve({status: 200, data: journals});
    axios.get.mockImplementationOnce(() => options);

    render(<PrelimInfo importInfo="manuscript" {...info} />);

    const input = screen.getByLabelText('Journal name:', {exact: true});

    userEvent.clear(input);
    userEvent.type(input, 'PLOS NEW');

    await waitFor(() => options);

    const data = {error: null, reloadPage: false};
    const promise = Promise.resolve({status: 200, data});
    axios.patch.mockImplementationOnce(() => promise);

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(8));

    userEvent.click(document.body);

    const checkbox = screen.getByLabelText('I cannot find my journal name, "PLOS NEW", in the list');

    await waitFor(() => {
      expect(checkbox).toBeInTheDocument();
    });

    userEvent.click(checkbox);
    await waitFor(() => {
      expect(checkbox.checked).toEqual(true);
    });

    await waitFor(() => promise);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', 'PLOS NEW');
    });
  });
});
