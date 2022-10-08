import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import RelatedWorkForm from "../../../../../app/javascript/react/components/MetadataEntry/RelatedWorkForm";
import axios from 'axios';

jest.mock('axios');

describe('RelatedWorkForm', () => {

  let relatedIdentifier, info;
  const relatedTypes = [
      ["Article","article"],
      ["Dataset","dataset"],
      ["Preprint","preprint"],
      ["Software","software"],
      ["Supplemental Information","supplemental_information"],
      ["Data Management Plan","data_management_plan"]
  ]

  // relatedIdentifier, workTypes, removeFunction, updateWork,
  beforeEach(() => {
    const resourceId = faker.datatype.number();
    relatedIdentifier = {"id": faker.datatype.number(),
      "related_identifier": faker.internet.url(),
      "related_identifier_type": "url",
      "relation_type": "cites",
      "resource_id": resourceId,
      "work_type": "article",
      "verified": true,
      "valid_url_format": true
    }


    info = {
      relatedIdentifier: relatedIdentifier,
      workTypes: relatedTypes,
      removeFunction: jest.fn(),
      updateWork: jest.fn(),
    }
  });

  it("renders the basic Related Work form", () => {
    render(<RelatedWorkForm {...info} />);

    expect(screen.getByLabelText('Work Type')).toHaveValue('article');

    expect(screen.getByLabelText('Identifier or external url')).toHaveValue(info.relatedIdentifier.related_identifier);
  });

  // gives some pointers and info about act and async examples
  // https://javascript.plainenglish.io/you-probably-dont-need-act-in-your-react-tests-2a0bcd2ad65c
  it("checks that updating related_identifier triggers axios call", async () => {

    const promise = Promise.resolve({
      status: 200,
      data: info.contributor
    })

    axios.patch.mockImplementationOnce(() => promise);

    render(<RelatedWorkForm {...info} />);

    userEvent.clear(screen.getByLabelText('Identifier or external url'));
    userEvent.type(screen.getByLabelText('Identifier or external url'), 'http://example.com');

    await waitFor(() => expect(screen.getByLabelText('Identifier or external url')).toHaveValue('http://example.com'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByText('remove')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
    // This gives a warning when it runs in the console since we don't have the global JS items we use to display saving message
    // but it doesn't fail and test passes.
  })

});