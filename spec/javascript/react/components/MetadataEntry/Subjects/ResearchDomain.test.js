import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import ResearchDomain from '../../../../../../app/javascript/react/components/MetadataEntry/Subjects/ResearchDomain';

jest.mock('axios');

describe('ResearchDomain', () => {
  let resource; let subject; let subjectList;
  const setResource = () => {};

  beforeEach(() => {
    subjectList = [];
    // make fake list of names
    for (let i = 0; i < 30; i += 1) {
      subjectList.push({subject: faker.company.companyName(), subject_scheme: 'fos'});
    }
    subject = subjectList[10]; /* eslint-disable-line */
    resource = {
      id: faker.datatype.number(),
      subjects: [
        subject,
      ],
    };
  });

  // {resourceId, subject, subjectList, updatePath}
  it('renders basic Research domain form', async () => {
    axios.get.mockResolvedValue({data: subjectList.map((s) => s.subject)});
    render(<ResearchDomain resource={resource} setResource={setResource} />);

    await waitFor(() => subjectList.map((s) => s.subject));
    expect(screen.getByLabelText('Research domains')).toBeVisible();
  });
});
