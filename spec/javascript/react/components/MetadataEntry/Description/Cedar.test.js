import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {faker} from '@faker-js/faker';
import Cedar from '../../../../../../app/javascript/react/components/MetadataEntry/Description/Cedar';

const xhrMockClass = () => ({
  open: jest.fn(),
  send: jest.fn(),
  setRequestHeader: jest.fn(),
});

describe('Cedar', () => {
  let resource; let editorUrl; let templates; let templateName;
  const setResource = (item) => { resource = item; };
  beforeEach(() => {
    window.XMLHttpRequest = jest.fn().mockImplementation(xhrMockClass);
    HTMLDialogElement.prototype.show = jest.fn(function mock() { this.open = true; });
    HTMLDialogElement.prototype.showModal = jest.fn(function mock() { this.open = true; });
    HTMLDialogElement.prototype.close = jest.fn(function mock() { this.open = false; });
    resource = {
      id: faker.datatype.number(),
      title: faker.lorem.sentence(),
      cedar_json: null,
    };
    editorUrl = 'https://raw.githubusercontent.com/datadryad/dryad-app/main/public/cedar-embeddable-editor/cedar-embeddable-editor.js';
    templateName = faker.lorem.words(3);
    templates = [[1, 'Empty template'], [2, templateName]];
  });

  it('does not render when there are no templates', () => {
    templates = null;
    render(<Cedar resource={resource} setResource={setResource} editorUrl={editorUrl} templates={templates} />);
    expect(screen.queryByText('Choose a metadata form')).not.toBeInTheDocument();
  });

  it('renders a select box', () => {
    render(<Cedar resource={resource} setResource={setResource} editorUrl={editorUrl} templates={templates} />);
    expect(screen.queryByText('Choose a metadata form')).toBeInTheDocument();

    const options = screen.getAllByRole('option');
    expect(options.length).toBe(3);
    const optionNames = options.map((o) => o.label);
    expect(optionNames).toEqual(['- Select one -', 'Empty template', templateName]);
  });

  it('renders an indicator that metadata is present', () => {
    resource.cedar_json = `{ "template": {"id":"2","title":"${templateName}"}, "metadata": 2, "updated": 3 }`;
    render(<Cedar resource={resource} setResource={setResource} editorUrl={editorUrl} templates={templates} />);

    expect(screen.getByText(templateName)).toBeInTheDocument();
    expect(screen.getByText('Edit form')).toBeInTheDocument();
    expect(screen.getByText('Delete form')).toBeInTheDocument();
  });

  it('opens the editor modal', async () => {
    resource.cedar_json = `{ "template": {"id":"1","title":"${templateName}"}, "metadata": 2, "updated": 3 }`;
    render(<Cedar resource={resource} setResource={setResource} editorUrl={editorUrl} templates={templates} />);

    userEvent.click(screen.getByText('Edit form'));
    await waitFor(() => {
      expect(screen.getAllByRole('dialog')[0]).toBeVisible();
    });
  });

  it('deletes a metadata form', async () => {
    resource.cedar_json = `{ "template": {"id":"1","title":"${templateName}"}, "metadata": 2, "updated": 3 }`;
    render(<Cedar resource={resource} setResource={setResource} editorUrl={editorUrl} templates={templates} />);

    userEvent.click(screen.queryByText('Delete form'));
    await waitFor(() => {
      expect(screen.queryByText('Cancel')).toBeVisible();
    });
    userEvent.click(screen.queryByText('Delete Form'));
    await waitFor(() => {
      expect(screen.queryByText('Choose a metadata form')).toBeInTheDocument();
    });
  });

  it('does not delete a metadata form', async () => {
    resource.cedar_json = `{ "template": {"id":"1","title":"${templateName}"}, "metadata": 2, "updated": 3 }`;
    render(<Cedar resource={resource} setResource={setResource} editorUrl={editorUrl} templates={templates} />);

    userEvent.click(screen.queryByText('Delete form'));
    await waitFor(() => {
      expect(screen.queryByText('Cancel')).toBeVisible();
    });
    userEvent.click(screen.queryByText('Cancel'));
    await waitFor(() => {
      expect(screen.queryByText('Choose a metadata form')).not.toBeInTheDocument();
    });
  });
});
