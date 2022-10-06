/**
 * @jest-environment jsdom
 */

/* some resources for testing, need to have a better understanding of how testing works like a training course
https://medium.com/@kylefox/how-to-setup-javascript-testing-in-rails-5-1-with-webpacker-and-jest-ef7130a4c08e
https://jestjs.io/docs/configuration
https://jest-bot.github.io/jest/docs/configuration.html
https://reactjs.org/docs/testing-recipes.html
https://reactjs.org/docs/test-utils.html
https://www.freecodecamp.org/news/testing-react-hooks/
https://www.valentinog.com/blog/testing-react/
https://reactjs.org/docs/test-renderer.html

const uploadFiles = require('UploadFiles.js');

to run try 'yarn jest'
if you need to see console.log output, do 'yarn jest --verbose false'
 */

import ReactDOM, {unmountComponentAtNode} from "react-dom";
import React from 'react';
import {act} from 'react-dom/test-utils';
import {create} from "react-test-renderer";
import UploadFiles from '../../../../app/javascript/react/containers/FileUpload/UploadFiles';

let container = null;
beforeEach(() => {
  // setup a DOM element as a render target
  container = document.createElement("div");
  document.body.appendChild(container);
});

afterEach(() => {
  // cleanup on exiting
  unmountComponentAtNode(container);
  container.remove();
  container = null;
});

describe('upload files', () => {

  let upFiles;
  beforeEach(() => {
    upFiles = create(<UploadFiles
        resource_id={333}
        file_uploads={[]}
        app_config_s3={{region: "us-west-2", bucket: "a-test-bucket", key: "abcdefg"}}
        s3_dir_name={"b759e787-333"}
    />)
  });

  afterEach(() => {
    upFiles = null;
  });

  it('does a basic test that UploadFiles loads and checks for data manifest button', () => {
    act(() => {
      ReactDOM.render(<UploadFiles
          resource_id={333}
          file_uploads={[]}
          app_config_s3={{region: "us-west-2", bucket: "a-test-bucket", key: "abcdefg"}}
          s3_dir_name={"b759e787-333"}
      />, container);
    });
    const button = container.querySelector('button#data_manifest');
    expect(button).toBeDefined();
  });

  describe('hasPendingFiles', () => {

    // pending files do not have ids yet
    it('returns false if no files', () => {
      const upInstance = upFiles.getInstance();
      expect(upInstance.hasPendingFiles()).toBeFalsy();
    });

    it("is false if files have ids or status besides pending", () => {
      const upInstance = upFiles.getInstance();
      upInstance.state.chosenFiles = [{id: 2737, status: 'Uploaded'}, {id: 3732, status: 'Uploaded'}];
      expect(upInstance.hasPendingFiles()).toBeFalsy();
    });

    it("is true if any files don't have ids", () => {
      const upInstance = upFiles.getInstance();
      upInstance.state.chosenFiles = [{id: 2737, status: 'Uploaded'}, {name: "fun.jpg", status: 'Pending'}];
      expect(upInstance.hasPendingFiles()).toBeTruthy();
    });
  });
});
