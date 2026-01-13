import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Authors from '../../../../../../app/javascript/react/components/MetadataEntry/Authors';

jest.mock('../../../../../../app/javascript/react/shared/store', () => ({
  useStore: () => ({
    storeState: {fees: 999},
    updateStore: jest.fn(),
  }),
}));

jest.mock('axios');

const makeAuthor = (resource_id, myOrder) => {
  const sect = () => faker.datatype.number({min: 1000, max: 9999});
  return {
    id: faker.datatype.number({min: 1, max: 32767}),
    author_first_name: faker.name.firstName(),
    author_last_name: faker.name.lastName(),
    author_org_name: null,
    author_email: faker.internet.email(),
    author_orcid: `${sect()}-${sect()}-${sect()}-${sect()}`,
    resource_id: resource_id || faker.datatype.number({min: 1, max: 32767}),
    author_order: myOrder,
    orcid_invite_path: faker.internet.url(),
    affiliations: [],
  };
};

describe('Authors', () => {
  let resource; let user; let dryadAuthors;
  const setResource = (item) => { resource = item; };
  beforeEach(() => {
    const rid = faker.datatype.number();
    dryadAuthors = (new Array(3).fill(null)).map((_item, idx) => makeAuthor(rid, (2 - idx)));
    resource = {
      id: rid,
      authors: dryadAuthors,
      users: [{
        id: 1,
        first_name: dryadAuthors[0].author_first_name,
        last_name: dryadAuthors[0].author_last_name,
        role: 'creator',
        orcid: dryadAuthors[0].author_orcid,
        email: dryadAuthors[0].author_email,
      }, {
        id: 1,
        first_name: dryadAuthors[0].author_first_name,
        last_name: dryadAuthors[0].author_last_name,
        role: 'submitter',
        orcid: dryadAuthors[0].author_orcid,
        email: dryadAuthors[0].author_email,
      }],
    };
    user = {id: 1, curator: false, superuser: false};
  });

  it('renders multiple authors in authors section', () => {
    render(<Authors resource={resource} setResource={setResource} user={user} />);

    const labeledElements = screen.getAllByLabelText('Institutional affiliation', {exact: false});
    expect(labeledElements.length).toBe(3);
    const firsts = screen.getAllByLabelText('First name', {exact: false});
    expect(firsts.length).toBe(3);
    expect(firsts[0]).toHaveValue(dryadAuthors[2].author_first_name);
    expect(firsts[2]).toHaveValue(dryadAuthors[0].author_first_name);

    expect(screen.getByText('+ Add author')).toBeInTheDocument();
  });

  it('removes an author from the document', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: resource.authors[2],
    });

    axios.delete.mockImplementationOnce(() => promise);

    render(<Authors resource={resource} setResource={setResource} user={user} />);

    let removes = screen.getAllByLabelText('Remove author');
    expect(removes.length).toBe(3);

    userEvent.click(removes[2]);

    await waitFor(() => promise); // waits for the axios promise to fulfill

    removes = screen.getAllByLabelText('Remove author');
    expect(removes.length).toBe(2);
  });

  it('adds an author to the document', async () => {
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
        affiliations: [],
      },
    });

    axios.post.mockImplementationOnce(() => promise);

    render(<Authors resource={resource} setResource={setResource} user={user} />);

    const removes = screen.getAllByLabelText('Remove author');
    expect(removes.length).toBe(3);

    userEvent.click(screen.getByText('+ Add author'));

    await waitFor(() => {
      expect(screen.getAllByLabelText('Remove author').length).toBe(4);
    });
  });

  it('should trigger drag and drop', async () => {
    const promise = Promise.resolve({status: 200, data: []});
    axios.patch.mockImplementationOnce(() => promise);
    render(<Authors resource={resource} setResource={setResource} user={user} />);

    await waitFor(() => {
      expect(screen.getAllByRole('listitem').length).toBe(3);
    });

    const button = screen.getAllByRole('button')[0];

    userEvent.tab();
    expect(button.matches(':focus')).toBe(true);

    userEvent.keyboard('[Enter]');
    expect(button).toHaveAttribute('aria-pressed', 'true');
    userEvent.keyboard('[Enter]');
    expect(button).toHaveAttribute('aria-pressed', 'false');
    userEvent.keyboard('[Enter]');
    expect(button).toHaveAttribute('aria-pressed', 'true');
  });
});
