import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import ResearchDomain from '../../../../../app/javascript/react/components/MetadataEntry/ResearchDomain';

jest.mock('axios');

describe('ResearchDomain', () => {
  let resourceId; let subject; let subjectList; let
    updatePath;

  beforeEach(() => {
    resourceId = faker.datatype.number();
    updatePath = faker.system.directoryPath();

    subjectList = [];
    // make fake list of names
    for (let i = 0; i < 30; i += 1) {
      subjectList.push(faker.company.companyName());
    }

    subject = subjectList[10]; /* eslint-disable-line */
  });

  // {resourceId, subject, subjectList, updatePath}
  it('renders basic Research domain form', () => {
    render(<ResearchDomain
      resourceId={resourceId}
      subject={subject}
      subjectList={subjectList}
      updatePath={updatePath}
    />);

    const resDomain = screen.getByLabelText('Research domain', {exact: false});
    expect(resDomain).toHaveValue(subject);
  });

  it('calls axios to update from server on change', async () => {
    const promise = Promise.resolve({
      data: subjectList[20],
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<ResearchDomain
      resourceId={resourceId}
      subject={subject}
      subjectList={subjectList}
      updatePath={updatePath}
    />);

    const resDomain = screen.getByLabelText('Research domain', {exact: false});
    expect(resDomain).toHaveValue(subject);

    userEvent.clear(screen.getByLabelText('Research domain'));
    userEvent.type(screen.getByLabelText('Research domain'), subjectList[20]);

    await waitFor(() => expect(screen.getByLabelText('Research domain')).toHaveValue(subjectList[20]));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});
