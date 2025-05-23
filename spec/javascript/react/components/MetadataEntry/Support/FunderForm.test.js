import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import groupings from './funderGroupings.json';
import FunderForm from '../../../../../../app/javascript/react/components/MetadataEntry/Support/FunderForm';

jest.mock('axios');

describe('FunderForm', () => {
  let resourceId; let
    info;
  beforeEach(() => {
    resourceId = faker.datatype.number();
    info = {
      resourceId,
      origID: faker.datatype.string(10),
      contributor:
          {
            id: faker.datatype.number(),
            contributor_name: faker.company.companyName(),
            contributor_type: 'funder',
            identifier_type: null,
            name_identifier_id: null,
            resourceId,
            award_number: faker.datatype.string(5),
            award_description: faker.datatype.string(10),
            funder_order: null,
          },
      createPath: faker.system.directoryPath(),
      updatePath: faker.system.directoryPath(),
      reorderPath: faker.system.directoryPath(),
      removeFunction: jest.fn(),
      updateFunder: jest.fn(),
      groupings,
    };
  });

  it('renders the basic funders form', () => {
    render(<FunderForm {...info} />);

    const labeledElements = screen.getAllByLabelText('Granting organization', {exact: false});
    expect(labeledElements.length).toBe(4);
    expect(labeledElements[0]).toHaveAttribute('value', info.contributor.contributor_name);

    expect(screen.getByLabelText('Award number')).toHaveValue(info.contributor.award_number);
  });

  it('selects from autocomplete options shown while typing', async () => {
    const options = Promise.resolve({
      status: 200,
      data: [
        {
          id: 'https://ror.org/05cy4wa09', name: 'Wellcome Sanger Institute', country: 'United Kingdom', acronyms: ['WTSI'],
        },
        {
          id: 'https://ror.org/029chgv08', name: 'Wellcome Trust', country: 'United Kingdom', acronyms: ['WT'],
        },
        {
          id: 'https://ror.org/03hamhx47', name: 'University of Massachusetts Lowell', country: 'United States', acronyms: [],
        },
      ],
    });

    axios.get.mockImplementationOnce(() => options);

    render(<FunderForm {...info} />);

    const input = screen.getByLabelText('Granting organization');

    userEvent.clear(input);
    userEvent.type(input, 'Well');

    await waitFor(() => options);

    const newFunder = {
      id: faker.datatype.number(),
      contributor_name: 'Wellcome Trust',
      contributor_type: 'funder',
      identifier_type: 'ror',
      name_identifier_id: 'https://ror.org/029chgv08',
    };

    const promise = Promise.resolve({status: 200, data: newFunder});

    axios.patch.mockImplementationOnce(() => promise);
    axios.patch.mockImplementationOnce(() => promise);

    const menu = screen.getByLabelText('Granting organization autocomplete list');
    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(4));

    userEvent.selectOptions(menu, screen.getByText(/Wellcome Trust/));

    await waitFor(() => promise);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', newFunder.contributor_name);
    });
  });

  it('shows sub-list when groupings exist and selects from it', async () => {
    const {contributor} = info;
    contributor.contributor_name = 'National Institutes of Health';
    contributor.name_identifier_id = 'https://ror.org/01cwqze88';
    contributor.name_identifier_type = 'ror';

    const group = groupings[0].json_contains;

    const promise = Promise.resolve({status: 200, data: group[8]});

    axios.patch.mockImplementationOnce(() => promise);

    const {contributor: c, ...rest} = info;

    render(<FunderForm contributor={contributor} {...rest} />);

    const select = screen.getByLabelText('NIH Directorate', {exact: false});

    userEvent.selectOptions(select, group[8].contributor_name);

    const input = screen.getByLabelText('Granting organization');

    await waitFor(() => promise);

    await waitFor(() => {
      expect(input).toHaveAttribute('value', group[8].contributor_name);
    });
  });

  // gives some pointers and info about act and async examples
  // https://javascript.plainenglish.io/you-probably-dont-need-act-in-your-react-tests-2a0bcd2ad65c
  it('checks that updating funder award number triggers the save event and does axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: info.contributor,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<FunderForm {...info} />);

    userEvent.clear(screen.getByLabelText('Award number'));
    userEvent.type(screen.getByLabelText('Award number'), 'alf234');

    await waitFor(() => expect(screen.getByLabelText('Award number')).toHaveValue('alf234'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByLabelText('Program/division')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
    // This gives a warning when it runs in the console since we don't have the global JS items we use to display saving message
    // but it doesn't fail and test passes.
  });

  it('checks that updating program/division triggers the save event and does axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: info.contributor,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<FunderForm {...info} />);

    userEvent.clear(screen.getByLabelText('Program/division'));
    userEvent.type(screen.getByLabelText('Program/division'), 'TEvasafsdf');

    await waitFor(() => expect(screen.getByLabelText('Program/division')).toHaveValue('TEvasafsdf'));

    userEvent.tab(); // tab out of element, should trigger save on blur
    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
