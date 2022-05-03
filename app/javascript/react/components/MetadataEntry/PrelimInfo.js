import React, {useState} from 'react';
import axios from 'axios';
import PropTypes from 'prop-types';
import PrelimManu from './PrelimManu';
import PrelimArticle from './PrelimArticle';
import PrelimOther from './PrelimOther';
import {showSavedMsg, showSavingMsg} from '../../../lib/utils';

function PrelimInfo(
  {
    importInfo, resourceId, identifierId, publication_name, publication_issn, msid, related_identifier,
  },
) {
  const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content');

  const [importType, setImportType] = useState(importInfo);

  const optionChange = (choice) => {
    setImportType(choice);

    axios.patch(
      `/stash/resources/${resourceId}/import_type`,
      {authenticity_token: csrf, import_info: choice},
      {headers: {'Content-Type': 'application/json; charset=utf-8', Accept: 'application/json'}},
    )
      .then((data) => {
        if (data.status !== 200) {
          console.log("couldn't change import_type on remote server");
        }
      });
  };

  return (
    <>
      <div className="js-contributors_form_top">
        <p id="import-choices-label">My data is related to:</p>
      </div>

      <div className="c-import__choicesbox js-import-choice" role="group" aria-labelledby="import-choices-label">
        <div className="c-import__choicebox">
          <div className="c-import__icon"><i className="fa fa-pencil-square-o fa-3x" /></div>
          <div>
            <input
              type="radio"
              name="import_type"
              id="choose_manuscript"
              value="manuscript"
              checked={importType === 'manuscript'}
              onChange={() => { optionChange('manuscript'); }}
            />
            <label htmlFor="choose_manuscript">&nbsp;a manuscript in progress</label>
          </div>
        </div>

        <div className="c-import__choicebox">
          <div className="c-import__icon"><i className="fa fa-file-text-o fa-3x" /></div>
          <div>
            <input
              type="radio"
              name="import_type"
              id="choose_published"
              value="published"
              checked={importType === 'published'}
              onChange={() => { optionChange('published'); }}
            />
            <label htmlFor="choose_published">&nbsp;a published article</label>
          </div>
        </div>

        <div className="c-import__choicebox">
          <div className="c-import__icon"><i className="fa fa-table fa-3x" /></div>
          <div>
            <input
              type="radio"
              name="import_type"
              id="choose_other"
              value="other"
              checked={importType === 'other'}
              onChange={() => { optionChange('other'); }}
            />
            <label htmlFor="choose_other">&nbsp;other or not applicable</label>
          </div>
        </div>
      </div>

      {(() => {
        switch (importType) {
          case 'manuscript':
            return (
              <PrelimManu
                resourceId={resourceId}
                identifierId={identifierId}
                publication_name={publication_name}
                publication_issn={publication_issn}
                msid={msid}
              />
            );
            break;
          case 'published':
            return (
              <PrelimArticle
                resourceId={resourceId}
                identifierId={identifierId}
                publication_name={publication_name}
                publication_issn={publication_issn}
                related_identifier={related_identifier}
              />
            );
            break;
          default:
            return (<PrelimOther />);
        }
      }
      )()}

    </>
  );
}

export default PrelimInfo;
