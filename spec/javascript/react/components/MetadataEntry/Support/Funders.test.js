import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Funders from '../../../../../../app/javascript/react/components/MetadataEntry/Support/Funders';

jest.mock('axios');

describe('Funders', () => {
  let contributors; let resource;
  const setResource = () => {};

  beforeEach(() => {
    const resourceId = faker.datatype.number();
    contributors = [];
    // add 3 contributors
    for (let i = 0; i < 3; i += 1) {
      contributors.push(
        {
          id: faker.datatype.number(),
          contributor_name: faker.company.companyName(),
          contributor_type: 'funder',
          identifier_type: null,
          name_identifier_id: null,
          resource_id: resourceId,
          award_number: faker.datatype.string(5),
          award_description: faker.datatype.string(10),
          funder_order: i,
        },
      );
    }

    resource = {
      id: resourceId,
      contributors,
    };
  });

  it('renders multiple funder forms as funder section', async () => {
    const group = {status: 200, data: null};
    axios.post.mockResolvedValue(group);

    render(<Funders current resource={resource} setResource={setResource} />);

    const labeledElements = screen.getAllByLabelText('Granting organization');
    expect(labeledElements.length).toBe(3);
    const awardNums = screen.getAllByLabelText('Award number', {exact: false});
    expect(awardNums.length).toBe(3);
    expect(awardNums[0]).toHaveValue(contributors[0].award_number);
    expect(awardNums[2]).toHaveValue(contributors[2].award_number);

    expect(screen.getByText('+ Add funder')).toBeInTheDocument();
  });

  it('removes a funder from the document', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: contributors[2],
    });

    axios.delete.mockImplementationOnce(() => promise);

    render(<Funders current resource={resource} setResource={setResource} />);

    let removes = screen.getAllByLabelText('Remove funding');
    expect(removes.length).toBe(3);

    userEvent.click(removes[2]);

    await waitFor(() => promise); // waits for the axios promise to fulfill

    removes = screen.getAllByLabelText('Remove funding');
    expect(removes.length).toBe(2);
  });

  it('adds a funder to the document', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: {
        id: faker.datatype.number(),
        contributor_name: '',
        contributor_type: 'funder',
        identifier_type: 'ror',
        name_identifier_id: '',
        resource_id: resource.id,
      },
    });

    axios.post.mockImplementationOnce(() => promise);

    render(<Funders current resource={resource} setResource={setResource} />);

    const removes = screen.getAllByLabelText('Remove funding');
    expect(removes.length).toBe(3);

    userEvent.click(screen.getByText('+ Add funder'));

    await waitFor(() => {
      expect(screen.getAllByLabelText('Remove funding').length).toBe(4);
    });
  });

  it('Sets no funders', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: {
        id: faker.datatype.number(),
        contributor_name: '',
        contributor_type: 'funder',
        identifier_type: 'ror',
        name_identifier_id: '',
        resource_id: resource.id,
      },
    });
    const nofunder = Promise.resolve({
      status: 200,
      data: {
        id: faker.datatype.number(),
        contributor_name: 'N/A',
        contributor_type: 'funder',
        identifier_type: 'ror',
        name_identifier_id: '0',
        resource_id: resource.id,
      },
    });

    axios.post.mockImplementationOnce(() => promise);

    resource.contributors = [];
    render(<Funders current resource={resource} setResource={setResource} />);

    await waitFor(() => promise); // waits for the axios promise to fulfil

    const removes = screen.getAllByLabelText('Remove funding');
    expect(removes.length).toBe(1);

    axios.patch.mockImplementationOnce(() => nofunder);

    userEvent.click(screen.getByLabelText('No funding received'));
    await waitFor(() => nofunder);
    expect(screen.getByLabelText('No funding received').checked).toEqual(true);
  });
});
