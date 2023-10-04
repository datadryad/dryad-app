import React from 'react';
import {
  act, fireEvent, render, screen, waitFor,
} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import Keywords from '../../../../../app/javascript/react/components/MetadataEntry/Keywords';

jest.mock('axios');

describe('Keywords', () => {
  let resourceId; let subjects; let createPath; let
    deletePath;

  beforeEach(() => {
    subjects = [];

    resourceId = faker.datatype.number();
    // add 3 subjects
    for (let i = 0; i < 3; i += 1) {
      subjects.push(
        {
          id: faker.datatype.number(),
          subject: faker.lorem.word(),
          subject_scheme: null,
          scheme_uri: null,
        },
      );
    }

    createPath = faker.system.directoryPath();
    deletePath = faker.system.directoryPath();
  });

  it('renders the existing keywords', () => {
    render(<Keywords subjects={subjects} resourceId={resourceId} createPath={createPath} deletePath={deletePath} />);

    subjects.forEach((subj) => {
      expect(screen.getAllByText(subj.subject).length).toBeGreaterThanOrEqual(1);
    });
  });

  it('removes a keyword from the document', async () => {
    const promise = Promise.resolve({status: 200, data: subjects[0]});

    axios.delete.mockImplementationOnce(() => promise);

    const result = render(<Keywords subjects={subjects} resourceId={resourceId} createPath={createPath} deletePath={deletePath} />);
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
      subject: faker.lorem.word(),
      subject_scheme: null,
      scheme_uri: null,
    };

    const moreSubjects = [...subjects, extraSubj];

    const promise = Promise.resolve({status: 200, data: moreSubjects});

    axios.post.mockImplementationOnce(() => promise);

    render(<Keywords subjects={subjects} resourceId={resourceId} createPath={createPath} deletePath={deletePath} />);

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
