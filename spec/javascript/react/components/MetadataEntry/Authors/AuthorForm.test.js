import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import AuthorForm from '../../../../../../app/javascript/react/components/MetadataEntry/Authors/AuthorForm';

jest.mock('../../../../../../app/javascript/react/shared/store', () => ({
  useStore: () => ({
    storeState: {fees: 999},
    updateStore: jest.fn(),
  }),
}));
jest.mock('axios');

const makeAuthor = (resource_id = null, author_order = null) => {
  const sect = () => faker.datatype.number({min: 1000, max: 9999});
  return {
    author_first_name: faker.name.firstName(),
    author_last_name: faker.name.lastName(),
    author_org_name: null,
    author_email: faker.internet.email(),
    author_orcid: `${sect()}-${sect()}-${sect()}-${sect()}`,
    resource_id: resource_id || faker.datatype.number({min: 1, max: 32767}),
    author_order: author_order || faker.datatype.number({min: 1, max: 32767}),
    orcid_invite_path: faker.internet.url(),
    affiliations: [],
  };
};

describe('AuthorForm', () => {
  let author; let users; let user;
  const update = () => {};
  beforeEach(() => {
    author = makeAuthor();
    users = [{
      id: 1,
      first_name: author.author_first_name,
      last_name: author.author_last_name,
      role: 'creator',
      orcid: author.author_orcid,
      email: author.author_email,
    }, {
      id: 1,
      first_name: author.author_first_name,
      last_name: author.author_last_name,
      role: 'submitter',
      orcid: author.author_orcid,
      email: author.author_email,
    }];
    user = {id: 1, curator: false, superuser: false};
  });

  it('renders the basic author form', () => {
    render(<AuthorForm author={author} update={update} users={users} user={user} />);

    const labeledElements = screen.getAllByLabelText('Institutional affiliation', {exact: false});
    expect(labeledElements.length).toBe(1);

    expect(screen.getByLabelText('First name')).toHaveValue(author.author_first_name);
    expect(screen.getByLabelText('Last name')).toHaveValue(author.author_last_name);
    expect(screen.getByLabelText('Email address')).toHaveValue(author.author_email);
  });

  // gives some pointers and info about act and async examples
  // https://javascript.plainenglish.io/you-probably-dont-need-act-in-your-react-tests-2a0bcd2ad65c
  it('updating author triggers the save event and does axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: author,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<AuthorForm author={author} update={update} users={users} user={user} />);

    userEvent.clear(screen.getByLabelText('First name'));
    userEvent.type(screen.getByLabelText('First name'), 'Alphred');

    await waitFor(() => expect(screen.getByLabelText('First name')).toHaveValue('Alphred'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => expect(screen.getByLabelText('Last name')).toHaveFocus());
    await waitFor(() => promise); // waits for the axios promise to fulfil
    // This gives a warning when it runs in the console since we don't have the global JS items we use to display saving message
    // but it doesn't fail and test passes.
  });
  it('updating author triggers the save event and does axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: author,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<AuthorForm author={author} update={update} users={users} user={user} />);

    userEvent.clear(screen.getByLabelText('Last name'));
    userEvent.type(screen.getByLabelText('Last name'), 'Dryadsson');

    await waitFor(() => expect(screen.getByLabelText('Last name')).toHaveValue('Dryadsson'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
  it('updating author triggers the save event and does axios call', async () => {
    const promise = Promise.resolve({
      status: 200,
      data: author,
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<AuthorForm author={author} update={update} users={users} user={user} />);

    userEvent.clear(screen.getByLabelText('Email address'));
    userEvent.type(screen.getByLabelText('Email address'), 'email@email.edu');

    await waitFor(() => expect(screen.getByLabelText('Email address')).toHaveValue('email@email.edu'));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
