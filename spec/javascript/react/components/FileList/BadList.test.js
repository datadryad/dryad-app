/**
 * @jest-environment jsdom
 */

import ReactDOM, {unmountComponentAtNode} from 'react-dom';
import React from 'react';
import {act} from 'react-dom/test-utils';
import BadList from '../../../../../app/javascript/react/components/FileUpload/FileList/BadList';

let container = null;
beforeEach(() => {
  // setup a DOM element as a render target
  container = document.createElement('div');
  document.body.appendChild(container);
});

afterEach(() => {
  // cleanup on exiting
  unmountComponentAtNode(container);
  container.remove();
  container = null;
});

describe('BadList', () => {
  it("displays if couldn't read a file", () => {
    const testBad = [
      {
        upload_file_name: 'cat.csv',
        frictionless_report: {
          status: 'error',
        },
      },
    ];

    act(() => {
      ReactDOM.render(<BadList chosenFiles={testBad} />, container);
    });

    expect(container.textContent).toContain("couldn't read tabular data from cat.csv");
  });

  it('displays issues if they are present', () => {
    const testIssue = [
      {
        upload_file_name: 'simon.csv',
        frictionless_report: {
          status: 'issues',
        },
      },
    ];

    act(() => {
      ReactDOM.render(<BadList chosenFiles={testIssue} />, container);
    });

    expect(container.textContent).toContain('Our automated tabular data checker identified potential inconsistencies');
  });

  it("doesn't display anything if no frictionless on file", () => {
    const testFiles = [
      {
        upload_file_name: 'cassandra.jpg',
      },
    ];

    act(() => {
      ReactDOM.render(<BadList chosenFiles={testFiles} />, container);
    });

    expect(container.textContent).toBe('');
  });

  it("doesn't display anything if frictionless passed", () => {
    const testFiles = [
      {
        upload_file_name: 'awesome.csv',
        frictionless_report: {
          status: 'noissues',
        },
      },
    ];

    act(() => {
      ReactDOM.render(<BadList chosenFiles={testFiles} />, container);
    });

    expect(container.textContent).toBe('');
  });
});
