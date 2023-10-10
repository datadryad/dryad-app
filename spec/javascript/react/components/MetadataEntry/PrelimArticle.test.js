import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import PrelimArticle from '../../../../../app/javascript/react/components/MetadataEntry/PrelimArticle';

jest.mock('axios');

describe('PrelimArticle', () => {
  let info; let publication_name; let publication_issn;

  beforeEach(() => {
    const identifierId = faker.datatype.number();
    publication_name = {
      id: faker.datatype.number(),
      identifier_id: identifierId,
      data_type: 'publicationName',
      value: faker.company.companyName(),
    };
    publication_issn = {
      id: faker.datatype.number(),
      identifier_id: identifierId,
      data_type: 'publicationISSN',
      value: `${faker.datatype.number({min: 1000, max: 9999})}-${faker.datatype.number({min: 1000, max: 9999})}`,
    };
    info = {
      resourceId: faker.datatype.number(),
      identifierId,
      acText: publication_name.value,
      setAcText: jest.fn(),
      acID: publication_issn.value,
      setAcID: jest.fn(),
      relatedIdentifier: faker.internet.url(),
      setRelatedIdentifier: jest.fn(),
    };
  });

  it('renders the basic article and doi form', () => {
    render(<PrelimArticle {...info} />);

    const labeledElements = screen.getAllByLabelText('Journal name', {exact: false});
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', publication_name.value);
    expect(screen.getByLabelText('DOI')).toHaveValue(info.relatedIdentifier);
  });

  it('checks that updating fields triggers axios save on blur', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: {},
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimArticle {...info} />);

    userEvent.clear(screen.getByLabelText('DOI'));
    userEvent.type(screen.getByLabelText('DOI'), '12345.dryad/fa387gek');

    await waitFor(() => expect(screen.getByLabelText('DOI')).toHaveValue('12345.dryad/fa387gek'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByText('Import article metadata')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
  });

  it('checks that clicking button triggers axios save', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: {},
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<PrelimArticle {...info} />);

    userEvent.click(screen.getByText('Import article metadata'));
    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
