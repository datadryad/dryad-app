import React from 'react';

export default function UploadInput({
  id, changed, errorId, setWarning
}) {

  const getFiles = (entry) => {
    if (entry.isFile) {
      entry.file(file => {
        changed([file])
      })
    } else if (entry.isDirectory) {
      const reader = entry.createReader();
      reader.readEntries(entries => {
        for (const entry of entries) {
          getFiles(entry)
        }
      })
    }
  }

  const onDrop = (e) => {
    e.preventDefault();
    const {items} = e.dataTransfer
    for (const item of items) {
      if (!('getAsEntry' in item || 'webkitGetAsEntry' in item)) {
        setWarning(['Directories cannot be uploaded from your browser'])
        break
      }
      const entry = 'getAsEntry' in item ? item.getAsEntry() : item.webkitGetAsEntry();
      if (entry) getFiles(entry);
    }
  }

  return (
    <input
      id={id}
      type="file"
      onClick={(e) => { e.target.value = null; }}
      onDrop={onDrop}
      onChange={(e) => changed(e.target.files)}
      aria-errormessage={errorId}
      multiple
    />
  )
}