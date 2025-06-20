import React from 'react';
import {formatSizeUnits} from '../../../lib/utils';
import {ExitIcon} from '../ExitButton';

const fileList = (list, previous) => {
  const deleted = previous?.filter((p) => !list.some((f) => f.file_state === 'copied'
    && f.upload_file_name === p.upload_file_name && f.digest === p.digest
    && f.storage_version_id === p.storage_version_id));
  return (
    <>
      <ul className="c-review-files__list">
        {list.map((f) => {
          const isNew = f.file_state === 'created' || !previous.some((p) => p.upload_file_name === f.upload_file_name && p.digest === f.digest);
          const listing = <>{f.upload_file_name} <span className="file_size">{formatSizeUnits(f.upload_file_size)}</span></>;
          return (
            <li key={f.id}>
              {previous && isNew ? <ins>{listing}</ins> : listing}
            </li>
          );
        })}
      </ul>
      {deleted && deleted.length > 0 && (
        <ul className="c-review-files__list del">
          {deleted.map((d) => (
            <li key={d.id}>
              <del>{d.upload_file_name} <span className="file_size">{formatSizeUnits(d.upload_file_size)}</span></del>
            </li>
          ))}
        </ul>
      )}
    </>
  );
};

export default function FilesPreview({
  resource, previous, curator, maxSize,
}) {
  const present = resource.generic_files.filter((f) => f.file_state !== 'deleted');
  const data = present.filter((f) => f.type === 'StashEngine::DataFile' && f.upload_file_name !== 'README.md');
  const software = present.filter((f) => f.type === 'StashEngine::SoftwareFile');
  const supp = present.filter((f) => f.type === 'StashEngine::SuppFile');

  const prev_files = previous?.generic_files.filter((f) => f.file_state !== 'deleted');
  const prev_data = prev_files?.filter((f) => f.type === 'StashEngine::DataFile' && f.upload_file_name !== 'README.md');
  const prev_soft = prev_files?.filter((f) => f.type === 'StashEngine::SoftwareFile');
  const prev_supp = prev_files?.filter((f) => f.type === 'StashEngine::SuppFile');

  if (present.length > 0) {
    return (
      <>
        {data.length > 0 && (
          <>
            {curator && !resource.identifier.new_upload_size_limit && resource.total_file_size > maxSize && (
              <div className="callout warn">
                <p>
                  This dataset&apos;s total file size is {formatSizeUnits(resource.total_file_size)} (max {formatSizeUnits(maxSize)}).
                  It can only be submitted by a superuser.
                </p>
              </div>
            )}
            <h3 className="o-heading__level2">Data files hosted by Dryad</h3>
            {fileList(data, prev_data)}
          </>
        )}
        {software.length > 0 && (
          <>
            <h3 className="o-heading__level2">Software files hosted by <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<ExitIcon /></a></h3>
            {fileList(software, prev_soft)}
          </>
        )}
        {supp.length > 0 && (
          <>
            <h3 className="o-heading__level2">Supplemental files hosted by <a href="https://zenodo.org" target="_blank" rel="noreferrer">Zenodo<ExitIcon /></a></h3>
            {fileList(supp, prev_supp)}
          </>
        )}
      </>
    );
  }
  return null;
}
