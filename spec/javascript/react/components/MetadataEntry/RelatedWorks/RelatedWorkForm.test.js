import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import RelatedWorkForm from '../../../../../../app/javascript/react/components/MetadataEntry/RelatedWorks/RelatedWorkForm';

jest.mock('axios');
global.fetch = jest.fn(() => Promise.resolve({
  json: () => Promise.resolve({data: 100}),
}));
global.URL.canParse = () => true;

describe('RelatedWorkForm', () => {
  let relatedIdentifier; let
    info;
  const relatedTypes = [
    ['Article', 'article'],
    ['Dataset', 'dataset'],
    ['Preprint', 'preprint'],
    ['Software', 'software'],
    ['Supplemental information', 'supplemental_information'],
    ['Data management plan', 'data_management_plan'],
  ];

  // relatedIdentifier, workTypes, removeFunction, updateWork,
  beforeEach(() => {
    const resourceId = faker.datatype.number();
    relatedIdentifier = {
      id: faker.datatype.number(),
      related_identifier: faker.internet.url(),
      related_identifier_type: 'url',
      relation_type: 'cites',
      resource_id: resourceId,
      work_type: 'article',
      verified: true,
      valid_url_format: true,
    };

    info = {
      relatedIdentifier,
      workTypes: relatedTypes,
      removeFunction: jest.fn(),
      updateWork: jest.fn(),
    };
  });

  it('renders the basic Related Work form', () => {
    render(<RelatedWorkForm {...info} />);

    expect(screen.getByLabelText('Work type')).toHaveValue('article');

    expect(screen.getByLabelText('DOI or other URL')).toHaveValue(info.relatedIdentifier.related_identifier);
  });

  // gives some pointers and info about act and async examples
  // https://javascript.plainenglish.io/you-probably-dont-need-act-in-your-react-tests-2a0bcd2ad65c
  it('checks that updating related_identifier triggers axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: info.contributor,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<RelatedWorkForm {...info} />);

    userEvent.clear(screen.getByLabelText('DOI or other URL'));
    userEvent.type(screen.getByLabelText('DOI or other URL'), 'http://example.com');

    await waitFor(() => expect(screen.getByLabelText('DOI or other URL')).toHaveValue('http://example.com'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByLabelText('Remove work')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
    // This gives a warning when it runs in the console since we don't have the global JS items we use to display saving message
    // but it doesn't fail and test passes.
  });

  it('checks that updating related work type triggers axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: info.contributor,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<RelatedWorkForm {...info} />);

    userEvent.selectOptions(screen.getByLabelText('Work type'), 'Software');

    await waitFor(() => expect(screen.getByLabelText('Work type')).toHaveValue('software'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByLabelText('DOI or other URL')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
