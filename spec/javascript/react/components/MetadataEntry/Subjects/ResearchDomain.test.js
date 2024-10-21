import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import {faker} from '@faker-js/faker';
import axios from 'axios';
import ResearchDomain from '../../../../../../app/javascript/react/components/MetadataEntry/Subjects/ResearchDomain';

jest.mock('axios');

describe('ResearchDomain', () => {
  let resource; let subject; let subjectList; let form;
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
    form = {
      data: `<label for="searchselect-fos_subjects__input">Research domain</label>
    <input type="text" id="searchselect-fos_subjects__input"/>`,
    };
  });

  // {resourceId, subject, subjectList, updatePath}
  it('renders basic Research domain form', async () => {
    axios.get.mockResolvedValue(form);
    render(<ResearchDomain resource={resource} setResource={setResource} />);

    await waitFor(() => form);
    expect(screen.getByLabelText('Research domain', {exact: false})).toBeVisible();
  });
});
