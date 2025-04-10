import React from 'react';
import {
  act, fireEvent, render, screen, waitFor,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Keywords from '../../../../../../app/javascript/react/components/MetadataEntry/Subjects/Keywords';

jest.mock('axios');

describe('Keywords', () => {
  let resource; let subjects;
  const setResource = () => {};

  beforeEach(() => {
    subjects = [];
    const words = faker.helpers.uniqueArray(faker.lorem.words, 3);
    // add 3 subjects
    for (let i = 0; i < 3; i += 1) {
      subjects.push(
        {
          id: faker.datatype.number(),
          subject: words[i],
          subject_scheme: null,
          scheme_uri: null,
        },
      );
    }
    resource = {
      id: faker.datatype.number(),
      subjects,
    };
  });

  it('renders the existing keywords', () => {
    render(<Keywords resource={resource} setResource={setResource} />);

    subjects.forEach((subj) => {
      expect(screen.getAllByText(subj.subject).length).toBeGreaterThanOrEqual(1);
    });
  });

  it('selects from autocomplete options shown while typing', async () => {
    const options = Promise.resolve({
      status: 200,
      data: [
        {id: 7219, name: 'Agroecology'},
        {id: 11645, name: 'Behavioral ecology'},
        {id: 11647, name: 'Chemical ecology'},
        {id: 11648, name: 'Coastal ecology'},
        {id: 924, name: 'Ecology'},
      ],
    });

    axios.get.mockImplementationOnce(() => options);

    render(<Keywords resource={resource} setResource={setResource} />);

    const input = screen.getAllByLabelText('Subject keywords', {exact: false})[0];
    userEvent.type(input, 'Eco');

    await waitFor(() => options);

    const extraSubj = {
      id: 924,
      subject: 'Ecology',
      subject_scheme: 'PLOS Subject Area Thesaurus',
      scheme_URI: 'https://github.com/PLOS/plos-thesaurus',
    };
    const moreSubjects = [...subjects, extraSubj];

    const promise = Promise.resolve({status: 200, data: moreSubjects});

    axios.post.mockImplementationOnce(() => promise);

    const menu = screen.getByLabelText('Autocomplete list');
    expect(menu).toBeVisible();

    await waitFor(() => expect(screen.getAllByRole('option')).toHaveLength(5));

    userEvent.selectOptions(menu, extraSubj.subject);

    await waitFor(() => promise);

    await waitFor(() => {
      expect(document.querySelectorAll('.c-keywords__keyword')[3].textContent).toEqual(extraSubj.subject);
    });
  });

  it('removes a keyword from the document', async () => {
    const promise = Promise.resolve({status: 200, data: subjects[0]});

    axios.delete.mockImplementationOnce(() => promise);

    const result = render(<Keywords resource={resource} setResource={setResource} />);
    const firstKeyword = result.container.querySelector(`#sub_remove_${subjects[0].id}`);
    userEvent.click(firstKeyword);

    await waitFor(() => promise); // waits for the axios promise to fulfill

    await waitFor(() => {
      expect(screen.queryByText(subjects[0].subject)).not.toBeInTheDocument();
    });
  });

  it('adds a keyword to the document', async () => {
    const extraSubj = {
      id: faker.datatype.number(),
      subject: faker.lorem.words(2),
      subject_scheme: null,
      scheme_uri: null,
    };

    const moreSubjects = [...subjects, extraSubj];

    const promise = Promise.resolve({status: 200, data: moreSubjects});

    axios.post.mockImplementationOnce(() => promise);

    render(<Keywords resource={resource} setResource={setResource} />);

    const labeledElements = screen.getAllByLabelText('', {exact: false});

    userEvent.clear(labeledElements[0]);

    fireEvent.focus(labeledElements[0]);

    await act(async () => {
      // info at: https://testing-library.com/docs/ecosystem-user-event/
      await userEvent.type(labeledElements[0], extraSubj.subject, {delay: 20});
    });

    await act(async () => userEvent.tab(labeledElements[0]));

    await waitFor(() => promise); // waits for the axios promise to fulfill

    await waitFor(() => {
      expect(screen.queryByText(extraSubj.subject)).toBeInTheDocument();
    });
  });
});
