import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import RelatedWorks from "../../../../../app/javascript/react/components/MetadataEntry/RelatedWorks";
import axios from 'axios';

jest.mock('axios');

describe('RelatedWorkds', () => {

  let works, resourceId;

  const relatedTypes = [
    ["Article","article"],
    ["Dataset","dataset"],
    ["Preprint","preprint"],
    ["Software","software"],
    ["Supplemental Information","supplemental_information"],
    ["Data Management Plan","data_management_plan"]
  ]

  beforeEach(() => {

    resourceId = faker.datatype.number();
    works = [];
    // add 3 works
    for(let i = 0; i < 3; i++){
      works.push(
          {"id": faker.datatype.number(),
            "related_identifier": faker.internet.url(),
            "related_identifier_type": "url",
            "relation_type": "cites",
            "resource_id": resourceId,
            "work_type": "article",
            "verified": true,
            "valid_url_format": true
          }
      );
    }
  });

  it("renders multiple related works forms as related works section", () => {
    render(<RelatedWorks resourceId={resourceId} relatedIdentifiers={works} workTypes={relatedTypes} />);

    const labeledElements = screen.getAllByLabelText('Work Type', { exact: false });
    expect(labeledElements.length).toBe(3); // two for each autocomplete list
    const relIds = screen.getAllByLabelText('Identifier or external url', { exact: false })
    expect(relIds.length).toBe(3);
    expect(relIds[0]).toHaveValue(works[0].related_identifier);
    expect(relIds[2]).toHaveValue(works[2].related_identifier);

    expect(screen.getByText('add another related work')).toBeInTheDocument();
  });

  it("removes a related work from the document", async () => {
    const promise = Promise.resolve({
      data: works[2]
    });

    axios.delete.mockImplementationOnce(() => promise);

    render(<RelatedWorks resourceId={resourceId} relatedIdentifiers={works} workTypes={relatedTypes} />);

    let removes = screen.getAllByText('remove');
    expect(removes.length).toBe(3);

    userEvent.click(removes[2]);

    await waitFor(() => promise); // waits for the axios promise to fulfill

    removes = screen.getAllByText('remove');
    expect(removes.length).toBe(2);
  });

  it("adds a related work to the document", async () => {

    const promise = Promise.resolve({
      status: 200,
      data: {"id": faker.datatype.number(),
        "related_identifier": '',
        "resource_id": resourceId,
        "work_type": "article",
      }
    });

    axios.post.mockImplementationOnce(() => promise);

    render(<RelatedWorks resourceId={resourceId} relatedIdentifiers={works} workTypes={relatedTypes} />);

    let removes = screen.getAllByText('remove');
    expect(removes.length).toBe(3);

    userEvent.click(screen.getByText('add another related work'))

    await waitFor(() => {
      expect(screen.getAllByText('remove').length).toBe(4)
    });
  });

});