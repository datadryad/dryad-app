import React from 'react';
import {render, screen} from '@testing-library/react';
import BadList from '../../../../../../app/javascript/react/components/UploadFiles/FileList/BadList';

describe('BadList', () => {
  it("displays if couldn't read a file", () => {
    const testBad = [
      {
        download_filename: 'cat.csv',
        frictionless_report: {
          status: 'error',
        },
      },
    ];

    render(<BadList chosenFiles={testBad} />);
    expect(screen.getByText(
      // eslint-disable-next-line max-len
      'Our tabular data checker couldn\'t read tabular data from cat.csv. If you expect them to have consistent tabular data, check that they are readable and formatted correctly.',
    )).toBeInTheDocument();
  });

  it('displays issues if they are present', () => {
    const testIssue = [
      {
        download_filename: 'simon.csv',
        frictionless_report: {
          status: 'issues',
        },
      },
    ];

    render(<BadList chosenFiles={testIssue} />);

    expect(screen.getByText(
      'Inconsistencies found in the format and structure of 1 of your tabular data files',
    )).toBeInTheDocument();
  });

  it("doesn't display anything if no frictionless on file", () => {
    const testFiles = [
      {
        download_filename: 'cassandra.jpg',
      },
    ];

    render(<BadList chosenFiles={testFiles} />);

    expect(screen.queryByText(
      'Inconsistencies found in the format and structure of 1 of your tabular data files',
    )).not.toBeInTheDocument();
  });

  it("doesn't display anything if frictionless passed", () => {
    const testFiles = [
      {
        download_filename: 'awesome.csv',
        frictionless_report: {
          status: 'noissues',
        },
      },
    ];

    render(<BadList chosenFiles={testFiles} />);

    expect(screen.queryByText(
      'Inconsistencies found in the format and structure of 1 of your tabular data files',
    )).not.toBeInTheDocument();
  });
});
