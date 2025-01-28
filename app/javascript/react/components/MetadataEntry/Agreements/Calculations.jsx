import React from 'react';
import {formatSizeUnits} from '../../../../lib/utils';

export default function Calculations({
  resource, previous, dpc, config,
}) {
  const {large_file_size, additional_storage_chunk_size: chunk_size, additional_storage_chunk_cost} = config;
  const chunk_cost = additional_storage_chunk_cost / 100;
  const published = resource.identifier.pub_state === 'published';
  const large_files = resource.total_file_size > large_file_size;
  let over = resource.total_file_size - large_file_size;
  if (published) {
    over = 0;
    if (large_files
        && resource.total_file_size > previous.total_file_size
        && Math.floor(resource.total_file_size / 10) !== Math.floor(previous.total_file_size / 10)) {
      over = resource.total_file_size - Math.max(previous.total_file_size, large_file_size);
    }
  }
  const chunks = Math.ceil(over / chunk_size);
  if (published) {
    return (
      <>
        <p>This dataset has already been published, and an invoice for Dryad&apos;s data publishing charge has already been sent.</p>
        {chunks > 0 && (
          <>
            <p>
              For data packages in excess of {formatSizeUnits(large_file_size)}, submitters will be charged{' '}
              an additional ${chunk_cost} for each additional {formatSizeUnits(chunk_size)}, or part thereof.
            </p>
            <p>
              For the addition of {formatSizeUnits(over)} to your published dataset,
              a new invoice will be sent for <b>${chunks * (chunk_cost)}</b>.
            </p>
          </>
        )}
      </>
    );
  }
  return (
    <>
      <p>
        Dryad charges a{large_files ? <> ${dpc}</> : ''} fee for the curation and preservation of published datasets.{' '}
        {large_files ? (
          <>
            For data packages in excess of {formatSizeUnits(large_file_size)}, submitters will be charged{' '}
            an additional ${chunk_cost} for each additional {formatSizeUnits(chunk_size)}, or part thereof.
          </>
        ) : (
          <>Upon publication of your dataset, an invoice will be sent for ${dpc}.</>
        )}
      </p>
      {large_files && (
        <p>
          Upon publication of your {formatSizeUnits(resource.total_file_size)} dataset,
          an invoice will be sent for <b>${dpc + (chunks * (chunk_cost))}</b>.
        </p>
      )}
    </>
  );
}
