import React from "react";
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import ResearchDomain from "../../../../../app/javascript/react/components/MetadataEntry/ResearchDomain.js";
import axios from 'axios';

jest.mock('axios');

describe('ResearchDomain', () => {

  let resourceId, subject, subjectList, updatePath;

  beforeEach(() => {

    resourceId = faker.datatype.number();
    updatePath = faker.system.directoryPath();

    subjectList = [];
    // make fake list of names
    for(let i = 0; i < 30; i++){
      subjectList.push(faker.company.companyName());
    }

    subject = subjectList[10];
  });

  // {resourceId, subject, subjectList, updatePath}
  it("renders basic Research Domain form", () => {
    render(<ResearchDomain
        resourceId={resourceId}
        subject={subject}
        subjectList={subjectList}
        updatePath={updatePath} />);

    const resDomain = screen.getByLabelText('Research Domain', { exact: false });
    expect(resDomain).toHaveValue(subject);
  });

  it("calls axios to update from server on change", async () => {

    const promise = Promise.resolve({
      data: subjectList[20]
    });

    axios.patch.mockImplementationOnce(() => promise);

    render(<ResearchDomain
        resourceId={resourceId}
        subject={subject}
        subjectList={subjectList}
        updatePath={updatePath} />);

    const resDomain = screen.getByLabelText('Research Domain', { exact: false });
    expect(resDomain).toHaveValue(subject);

    userEvent.clear(screen.getByLabelText('Research Domain'));
    userEvent.type(screen.getByLabelText('Research Domain'), subjectList[20]);

    await waitFor(() => expect(screen.getByLabelText('Research Domain')).toHaveValue(subjectList[20]));

    userEvent.tab(); // tab out of element, should trigger save on blur

    await waitFor(() => promise); // waits for the axios promise to fulfil
  });
});