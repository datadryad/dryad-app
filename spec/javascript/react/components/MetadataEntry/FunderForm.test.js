import React from "react";
import {render, screen} from '@testing-library/react';
// import axios from 'axios';

// jest.mock('axios');

describe('FunderForm', () => {

  let resourceId, origID, contributor, createPath, updatePath, removeFunction;
  beforeEach(() => {
    // fill values here
    // info = {resourceId, origID, contributor, createPath, updatePath, removeFunction}
  });

  it("renders the basic funders form", () => {

    const { container } = render(<FunderForm {...info} />);

    const labeledElements = screen.getAllByLabelText(info.controlOptions.labelText, { exact: false })
    expect(labeledElements.length).toBe(2);
    expect(labeledElements[0]).toHaveAttribute('value', acText);
  });
});