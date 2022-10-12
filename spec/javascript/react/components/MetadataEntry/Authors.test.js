import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import Authors from "../../../../../app/javascript/react/components/MetadataEntry/Authors";
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

    render(<Authors resource={resource} dryadAuthors={dryadAuthors} curator={curator} icon={icon} correspondingAuthorId={27} />);

    const labeledElements = screen.getAllByLabelText('Institutional Affiliation', { exact: false });
    expect(labeledElements.length).toBe(6); // two for each autocomplete list
    const firsts = screen.getAllByLabelText('First Name', { exact: false })
    expect(firsts.length).toBe(3);
    expect(firsts[0]).toHaveValue(dryadAuthors[2].author_first_name);
    expect(firsts[2]).toHaveValue(dryadAuthors[0].author_first_name);

    expect(screen.getByText('Add Author')).toBeInTheDocument();
  });

  it("removes an author from the document", async () => {
    const promise = Promise.resolve({
      data: dryadAuthors[2]
    });

    axios.delete.mockImplementationOnce(() => promise);

    render(<Authors resource={resource} dryadAuthors={dryadAuthors} curator={curator} icon={icon} correspondingAuthorId={27} />);

    let removes = screen.getAllByText('remove');
    expect(removes.length).toBe(3);

    userEvent.click(removes[2]);

    await waitFor(() => promise); // waits for the axios promise to fulfill

    removes = screen.getAllByText('remove');
    expect(removes.length).toBe(2);
  });

  it("adds an author to the document", async () => {

    const promise = Promise.resolve({
      status: 200,
      data: {
        id: faker.datatype.number({min: 1, max: 32767}),
        author_first_name: '',
        author_last_name: '',
        author_email: '',
        author_orcid: null,
        resource_id: resource.id,
        author_order: 33333,
        orcid_invite_path: '',
        affiliation: null
      }
    });

    axios.post.mockImplementationOnce(() => promise);

    render(<Authors resource={resource} dryadAuthors={dryadAuthors} curator={curator} icon={icon} correspondingAuthorId={27} />);

    let removes = screen.getAllByText('remove');
    expect(removes.length).toBe(3);

    userEvent.click(screen.getByText('Add Author'));

    await waitFor(() => {
      expect(screen.getAllByText('remove').length).toBe(4);
    });
  });

});