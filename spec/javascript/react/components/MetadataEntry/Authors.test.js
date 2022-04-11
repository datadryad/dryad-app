import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import Authors from "../../../../../app/javascript/react/components/MetadataEntry/Authors.js";
import axios from 'axios';

jest.mock('axios');

const makeAuthor = (resource_id = null, myOrder) => {
  const sect = () => faker.datatype.number({min:1000, max:9999});
  return {
    id: faker.datatype.number({min: 1, max: 32767}),
    author_first_name: faker.name.firstName(),
    author_last_name: faker.name.lastName(),
    author_email: faker.internet.email(),
    author_orcid: `${sect()}-${sect()}-${sect()}-${sect()}`,
    resource_id: resource_id || faker.datatype.number({min: 1, max: 32767}),
    author_order: myOrder,
    orcid_invite_path: faker.internet.url(),
    affiliation: null
  };
}

describe('Authors', () => {

  let resource, dryadAuthors, curator, icon;

  beforeEach(() => {

    resource = {id: faker.datatype.number()};

    // add 3 authors
    dryadAuthors = (new Array(3).fill(null)).map((_item, idx) => {
      return makeAuthor(resource.id, (2 - idx) );
    });

    curator = false;
    icon = ''; // no need to create fake icon path
  });

  it("renders multiple authors in authors section", () => {

    render(<Authors resource={resource} dryadAuthors={dryadAuthors} curator={curator} icon={icon} />);

    const labeledElements = screen.getAllByLabelText('Institutional Affiliation', { exact: false });
    expect(labeledElements.length).toBe(6); // two for each autocomplete list
    const firsts = screen.getAllByLabelText('First Name', { exact: false })
    expect(firsts.length).toBe(3);
    expect(firsts[0]).toHaveValue(dryadAuthors[2].author_first_name);
    expect(firsts[2]).toHaveValue(dryadAuthors[0].author_first_name);

    expect(screen.getByText('Add Author')).toBeInTheDocument();
  });

  /*
  it("removes a funder from the document", async () => {
    const promise = Promise.resolve({
      data: contributors[2]
    });

    axios.delete.mockImplementationOnce(() => promise);

    render(<Funders contributors={contributors} resourceId={resourceId} createPath={createPath} updatePath={updatePath}
                    deletePath={deletePath} />);

    let removes = screen.getAllByText('remove');
    expect(removes.length).toBe(3);

    userEvent.click(removes[2]);

    await waitFor(() => promise); // waits for the axios promise to fulfill

    removes = screen.getAllByText('remove');
    expect(removes.length).toBe(2);
  });

  it("adds a funder to the document", async () => {

    const promise = Promise.resolve({
      status: 200,
      data: {
        id: faker.datatype.number(),
        contributor_name: '',
        contributor_type: 'funder',
        identifier_type: 'crossref_funder_id',
        name_identifier_id: '',
        resource_id: resourceId,
      }
    });

    axios.post.mockImplementationOnce(() => promise);

    render(<Funders contributors={contributors} resourceId={resourceId} createPath={createPath} updatePath={updatePath}
                    deletePath={deletePath} />);

    let removes = screen.getAllByText('remove');
    expect(removes.length).toBe(3);

    userEvent.click(screen.getByText('add another funder'))

    await waitFor(() => {
      expect(screen.getAllByText('remove').length).toBe(4)
    });
  });
   */

});