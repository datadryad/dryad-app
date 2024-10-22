import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import RelatedWorks from '../../../../../../app/javascript/react/components/MetadataEntry/RelatedWorks';

jest.mock('axios');
global.URL.canParse = () => true;

describe('RelatedWorks', () => {
  let works; let resource;
  const setResource = () => {};

  const types = [
    ['Article', 'article'],
    ['Dataset', 'dataset'],
    ['Preprint', 'preprint'],
    ['Software', 'software'],
    ['Supplemental information', 'supplemental_information'],
    ['Data management plan', 'data_management_plan'],
  ];

  beforeEach(() => {
    const resourceId = faker.datatype.number();
    works = [];
    // add 3 works
    for (let i = 0; i < 3; i += 1) {
      works.push(
        {
          id: faker.datatype.number(),
          related_identifier: faker.internet.url(),
          related_identifier_type: 'url',
          relation_type: 'cites',
          resource_id: resourceId,
          work_type: 'article',
          verified: true,
          valid_url_format: true,
        },
      );
    }
    resource = {
      id: resourceId,
      resource_type: {resource_type: 'dataset'},
      related_identifiers: works,
    };
  });

  it('renders multiple related works forms as related works section', async () => {
    const data = {data: types};
    axios.get.mockResolvedValue(data);
    render(<RelatedWorks resource={resource} setResource={setResource} />);
    await waitFor(() => data);

    const labeledElements = screen.getAllByLabelText('Work type');
    expect(labeledElements.length).toBe(3); // two for each autocomplete list
    const relIds = screen.getAllByLabelText('DOI or other URL');
    expect(relIds.length).toBe(3);
    expect(relIds[0]).toHaveValue(works[0].related_identifier);
    expect(relIds[2]).toHaveValue(works[2].related_identifier);

    expect(screen.getByText('+ Add work')).toBeInTheDocument();
  });

  it('removes a related work from the document', async () => {
    const data = {status: 200, data: works[2]};
    axios.delete.mockResolvedValueOnce(data);

    render(<RelatedWorks resource={resource} setResource={setResource} />);

    let removes = screen.getAllByLabelText('Remove work');
    expect(removes.length).toBe(3);

    userEvent.click(removes[2]);

    await waitFor(() => data); // waits for the axios promise to fulfill

    removes = screen.getAllByLabelText('Remove work');
    expect(removes.length).toBe(2);
  });

  it('adds a related work to the document', async () => {
    const data = {
      status: 200,
      data: {
        id: faker.datatype.number(),
        related_identifier: '',
        resource_id: resource.id,
        work_type: 'article',
      },
    };
    axios.post.mockResolvedValueOnce(data);

    render(<RelatedWorks resource={resource} setResource={setResource} />);

    const removes = screen.getAllByLabelText('Remove work');
    expect(removes.length).toBe(3);

    userEvent.click(screen.getByText('+ Add work'));

    await waitFor(() => {
      expect(screen.getAllByLabelText('Remove work').length).toBe(4);
    });
  });

  it('adds an empty related work to the document', async () => {
    const data = {
      status: 200,
      data: {
        id: faker.datatype.number(),
        related_identifier: '',
        resource_id: resource.id,
        work_type: 'article',
      },
    };
    axios.post.mockResolvedValueOnce(data);

    resource.related_identifiers = [];

    render(<RelatedWorks resource={resource} setResource={setResource} />);

    await waitFor(() => data); // waits for the axios promise to fulfill
    const removes = screen.getAllByLabelText('Remove work');
    expect(removes.length).toBe(1);
  });
});
