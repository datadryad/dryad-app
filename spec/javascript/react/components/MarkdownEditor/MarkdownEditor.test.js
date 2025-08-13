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
