import React from 'react';
import {render, screen, waitFor} from '@testing-library/react';
import MarkdownEditor from '../../../../../app/javascript/react/components/MarkdownEditor';

describe('MarkdownEditor', () => {
  let info;
  beforeEach(() => {
    info = {
      id: 'editor',
      initialValue: '# This is some text',
      onChange: () => {},
      onReplace: () => {},
      buttons: [],
    };
  });

  it('renders both the milkdown and codemirror editors', async () => {
    render(<MarkdownEditor {...info} />);
    await waitFor(() => {
      expect(screen.getByText('This is some text')).toBeInTheDocument();
    });
    expect(document.querySelector('.milkdown')).toBeInTheDocument();
    expect(document.querySelector('.markdown_codemirror')).toBeInTheDocument();
    expect(screen.getByText('Markdown')).toBeInTheDocument();
    expect(screen.getByText('Rich text')).toBeInTheDocument();
  });

  it('renders desired buttons', async () => {
    info.buttons = ['strong', 'emphasis', 'strike_through'];
    render(<MarkdownEditor {...info} />);
    await waitFor(() => {
      expect(screen.getByText('This is some text')).toBeInTheDocument();
    });
    expect(screen.getByLabelText('Bold')).toBeInTheDocument();
    expect(screen.getByLabelText('Italic')).toBeInTheDocument();
    expect(screen.getByLabelText('Strikethrough text')).toBeInTheDocument();
  });

  it('renders a table', async () => {
    info.initialValue = '| Test  | Table  |\n| ------ | ------ |\n| Cell 1 | Cell 2 |';
    render(<MarkdownEditor {...info} />);
    await waitFor(() => {
      expect(screen.getByText('Cell 1')).toBeInTheDocument();
    });
    const table = document.querySelector('table');
    expect(table).toBeInTheDocument();
    expect(table.querySelectorAll('tr').length).toBe(2);
    expect(table.querySelectorAll('th').length).toBe(2);
    expect(table.querySelectorAll('td').length).toBe(2);
  });

  it('renders superscript and subscript', async () => {
    info.initialValue = 'Markdown test\n\nThis is a sentence with ^superscript^ and ~subscript~';
    render(<MarkdownEditor {...info} />);
    await waitFor(() => {
      expect(screen.getByText('Markdown test')).toBeInTheDocument();
    });
    const superscript = screen.getAllByText('superscript');
    const subscript = screen.getAllByText('subscript');
    expect(superscript[0].tagName).toBe('SUP');
    expect(subscript[0].tagName).toBe('SUB');
  });

  it('renders html input', async () => {
    const div = document.createElement('div');
    div.innerHTML = '<h2>This is an HTML header</h2><p>This is an HTML paragraph</p>';
    info.initialValue = null;
    info.htmlInput = div;
    render(<MarkdownEditor {...info} />);
    await waitFor(() => {
      expect(screen.getByText('This is an HTML header')).toBeInTheDocument();
    });
    expect(screen.getByText('This is an HTML paragraph')).toBeInTheDocument();
  });
});
