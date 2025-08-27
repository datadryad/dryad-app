import React, {useEffect} from 'react';
import {useSelect} from 'downshift';
import {editorViewCtx} from '@milkdown/kit/core';
import {callCommand} from '@milkdown/kit/utils';
import {commands} from '../milkdownCommands';
import {commands as mdCommands} from '../codeKeymap';
import {labels} from './Details';

export default function Heading({
  active, editor, mdEditor, activeEditor, headingLevel,
}) {
  const [selectedItem, setSelectedItem] = React.useState(headingLevel);
  useEffect(() => {
    setSelectedItem(headingLevel);
  }, [headingLevel]);
  const items = [1, 2, 3, 4, 5, 6, 0];
  const {
    isOpen,
    getToggleButtonProps,
    getMenuProps,
    getItemProps,
    highlightedIndex,
  } = useSelect({
    items,
    selectedItem,
    onSelectedItemChange: ({selectedItem: newSelectedItem}) => {
      setSelectedItem(newSelectedItem);
      if (activeEditor === 'visual') {
        editor()?.action(callCommand(commands.heading.key, newSelectedItem));
        const view = editor()?.ctx.get(editorViewCtx);
        view.focus();
      } else if (activeEditor === 'markdown') {
        mdCommands[`heading${newSelectedItem}`](mdEditor);
        mdEditor.focus();
      }
    },
  });
  return (
    <div className="headingSelect" role="menuitem">
      <div
        className={`headingButton${active ? ' active' : ''}`}
        role="button"
        aria-label={labels.heading}
        title={labels.heading}
        {...getToggleButtonProps({'aria-labelledby': null})}
        tabIndex="0"
      >
        <span>{selectedItem ? ((selectedItem === 1 && 'Title') || `Heading ${selectedItem}`) : 'Heading'}</span>
        <i className={`fas ${isOpen ? 'fa-chevron-up' : 'fa-chevron-down'}`} />
      </div>
      <ul hidden={!isOpen} {...getMenuProps()} className="headingMenu">
        {isOpen
          && items.map((item, index) => (
            <li
              className={`h${item} ${highlightedIndex === index ? 'highlighted ' : ''}${selectedItem === item ? 'selected' : ''}`}
              key={`heading${item}`}
              {...getItemProps({item, index})}
            >
              {(item === 0 && 'Normal text') || (item === 1 && 'Title') || `Heading ${item}`}
            </li>
          ))}
      </ul>
    </div>
  );
}
