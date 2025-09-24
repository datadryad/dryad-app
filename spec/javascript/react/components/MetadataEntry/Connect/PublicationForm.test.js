import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import PublicationForm from '../../../../../../app/javascript/react/components/MetadataEntry/Connect/PublicationForm';
import journals from './prelimjournals.json';

jest.mock('axios');

describe('PublicationFormPublished', () => {
  let resource_publication; let info; let primary_article; let related_identifiers; let update;
  const setResource = () => {};
  const setSponsored = () => {};

  beforeEach(() => {
    const resourceId = faker.datatype.number();
    const makeIssn = () => `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`;
    resource_publication = {
      publication_name: faker.company.companyName(),
      publication_issn: makeIssn(),
      manuscript_number: '',
    };
    primary_article = 'https://doi.org/10.111/Adahdjshf';
    related_identifiers = [{
      related_identifier: primary_article,
      work_type: 'primary_article',
    }];
    info = {
      current: true,
      setResource,
      setSponsored,
      importType: 'published',
      resource: {
        id: resourceId,
        title: '',
        resource_publication,
        related_identifiers,
      },
    };
    update = {
      status: 200,
      data: {
        journal: null,
        resource_publication,
        related_identifiers,
      },
    };
  });

  it('renders the basic article and doi form', async () => {
    render(<PublicationForm {...info} />);

    const labeledElements = screen.getAllByLabelText('Published article DOI');
    expect(labeledElements.length).toBe(1);
    expect(labeledElements[0]).toHaveValue(primary_article);
  });

  it('checks that updating fields triggers axios save on blur', async () => {
    axios.patch.mockResolvedValueOnce(update);
    render(<PublicationForm {...info} />);

    userEvent.clear(screen.getByLabelText('Published article DOI'));
    userEvent.type(screen.getByLabelText('Published article DOI'), '12345.dryad/fa387gek');

    await waitFor(() => expect(screen.getByLabelText('Published article DOI')).toHaveValue('12345.dryad/fa387gek'));

    userEvent.tab(); // tab out of element, should trigger save on blur
    await waitFor(() => update); // waits for the axios promise to fulfil

    const options = {status: 200, data: journals};
    axios.get.mockResolvedValueOnce(options);
  });
});

describe('PublicationFormManuscript', () => {
  let resource_publication; let info; let update;
  const setResource = () => {};
  const setSponsored = () => {};

  beforeEach(() => {
    const resourceId = faker.datatype.number();
    const makeIssn = () => `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`;
    resource_publication = {
      publication_name: faker.company.companyName(),
      publication_issn: makeIssn(),
      manuscript_number: 'TEST-MAN-NUM',
    };
    info = {
      current: true,
      setResource,
      setSponsored,
      importType: 'manuscript',
      resource: {
        id: resourceId,
        title: '',
        resource_publication,
        related_identifiers: [],
      },
    };
    update = {
      status: 200,
      data: {
        journal: null,
        resource_publication,
        related_identifiers: [],
      },
    };
  });

  it('renders the basic article and manuscript id form', async () => {
    render(<PublicationForm {...info} />);
    const labeledElements = screen.getAllByLabelText('Journal name');
    expect(labeledElements.length).toBe(1);
    expect(labeledElements[0]).toHaveAttribute('value', resource_publication.publication_name);
    expect(screen.getByLabelText('Manuscript number')).toHaveValue(resource_publication.manuscript_number);
  });

  it('checks that updating fields triggers axios save on blur', async () => {
    axios.patch.mockResolvedValueOnce(update);
    render(<PublicationForm {...info} />);

    userEvent.clear(screen.getByLabelText('Manuscript number'));
    userEvent.type(screen.getByLabelText('Manuscript number'), 'GUD-MS-387-555');

    await waitFor(() => expect(screen.getByLabelText('Manuscript number')).toHaveValue('GUD-MS-387-555'));

    userEvent.tab(); // tab out of element, should trigger save on blur
    await waitFor(() => update); // waits for the axios promise to fulfil
  });

  it('selects from journal autocomplete options shown while typing', async () => {
    render(<PublicationForm {...info} />);

    const options = {status: 200, data: journals};
    axios.get.mockResolvedValueOnce(options);

    const input = screen.getByLabelText('Journal name');

    userEvent.clear(input);
    userEvent.type(input, 'PLOS');

    await waitFor(() => options);

    const data = {status: 200, data: {error: null}};
    axios.patch.mockResolvedValueOnce(data);

    const menu = screen.getByLabelText('Journal name autocomplete list');
    expect(menu).toBeVisible();

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(9));

    userEvent.selectOptions(menu, 'PLOS ONE');

    await waitFor(() => data);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', 'PLOS ONE');
    });
  });

  it('saves journal that matches an autocomplete option', async () => {
    render(<PublicationForm {...info} />);

    const options = {status: 200, data: journals};
    axios.get.mockResolvedValueOnce(options);

    const input = screen.getByLabelText('Journal name');

    userEvent.clear(input);
    userEvent.type(input, 'PLOS ONE');

    await waitFor(() => options);

    const data = {status: 200, data: {error: null}};
    axios.patch.mockResolvedValueOnce(data);

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(9));

    userEvent.tab();

    await waitFor(() => data);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', 'PLOS ONE');
    });
  });

  it('saves text that does not match an autocomplete option', async () => {
    render(<PublicationForm {...info} />);

    const options = {status: 200, data: journals};
    axios.get.mockResolvedValueOnce(options);

    const input = screen.getByLabelText('Journal name');

    userEvent.clear(input);
    userEvent.type(input, 'PLOS NEW');

    await waitFor(() => options);

    const data = {status: 200, data: {error: null}};
    axios.patch.mockResolvedValueOnce(data);

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(9));

    userEvent.click(document.body);

    const checkbox = screen.getByLabelText('I cannot find my journal name, "PLOS NEW", in the list');

    await waitFor(() => {
      expect(checkbox).toBeInTheDocument();
    });

    userEvent.click(checkbox);
    await waitFor(() => {
      expect(checkbox.checked).toEqual(true);
    });

    await waitFor(() => data);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', 'PLOS NEW');
    });
  });
});
