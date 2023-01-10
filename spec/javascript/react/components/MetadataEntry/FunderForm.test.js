import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import FunderForm from "../../../../../app/javascript/react/components/MetadataEntry/FunderForm";
import axios from 'axios';

jest.mock('axios');

describe('FunderForm', () => {

  let resourceId, info;
  beforeEach(() => {
    resourceId = faker.datatype.number();
    info = {
      resourceId: resourceId,
      origID: faker.datatype.string(10),
      contributor:
          {
            id: faker.datatype.number(),
            contributor_name: faker.company.companyName(),
            contributor_type: 'funder',
            identifier_type: null,
            name_identifier_id: null,
            resourceId: resourceId,
            award_number: faker.datatype.string(5)
          },
      createPath: faker.system.directoryPath(),
      updatePath: faker.system.directoryPath(),
      removeFunction: jest.fn(),
      updateFunder: jest.fn(),
    }
  });

  it("renders the basic funders form", () => {
    render(<FunderForm {...info} />);

    const labeledElements = screen.getAllByLabelText('Granting organization', { exact: false });
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', info.contributor.contributor_name);

    expect(screen.getByLabelText('Award number')).toHaveValue(info.contributor.award_number);
  });

  // gives some pointers and info about act and async examples
  // https://javascript.plainenglish.io/you-probably-dont-need-act-in-your-react-tests-2a0bcd2ad65c
  it("checks that updating funder award number triggers the save event and does axios call", async () => {

    const promise = Promise.resolve({
      status: 200,
      data: info.contributor
    })

    axios.patch.mockImplementationOnce(() => promise);

    render(<FunderForm {...info} />);

    userEvent.clear(screen.getByLabelText('Award number'));
    userEvent.type(screen.getByLabelText('Award number'), 'alf234');

    await waitFor(() => expect(screen.getByLabelText('Award number')).toHaveValue('alf234'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByText('remove')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
    // This gives a warning when it runs in the console since we don't have the global JS items we use to display saving message
    // but it doesn't fail and test passes.
  })

});