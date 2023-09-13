import React, {useState} from 'react';
import axios from 'axios';

export default function TrackChanges({id, file_note}) {
  const [note, setNote] = useState(file_note);
  const [value, setValue] = useState(note?.note.split('User described file changes: ')[1]);

  const postNote = (e) => {
    axios.post(
      `/stash/file_note/${id}`,
      {
        id,
        note: e.currentTarget.value,
        note_id: note?.id,
      },
    ).then((response) => {
      setNote(response.data.note);
    });
  };

  return (
    <form className="c-upload__changes-form">
      <div>
        <label className="c-input__label" htmlFor="file-note-area">Please describe your file changes</label><br />
        <textarea
          className="c-input__textarea"
          id="file-note-area"
          value={value}
          onBlur={postNote}
          onChange={(e) => setValue(e.currentTarget.value)}
        />
      </div>
    </form>
  );
}
