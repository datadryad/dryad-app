import React from 'react';
import {formatSizeUnits} from '../../../../lib/utils';

export default function Calculations({
  resource, config,
}) {
  const {
    large_file_size, additional_storage_chunk_size: chunk_size, additional_storage_chunk_cost, data_processing_charge_new,
  } = config;
  const dpc = data_processing_charge_new / 100;
  const chunk_cost = additional_storage_chunk_cost / 100;
  const large_files = resource.total_file_size > large_file_size;
  const over = resource.total_file_size - large_file_size;
  const chunks = Math.ceil(over / chunk_size);
  return (
    <>
      <p>
        Dryad charges a{large_files ? <> ${dpc}</> : ''} Data Publishing Charge for the curation and preservation of published datasets.{' '}
        {large_files ? (
          <>
            For data packages in excess of {formatSizeUnits(large_file_size)}, submitters will be charged{' '}
            an additional ${chunk_cost} for each additional {formatSizeUnits(chunk_size)}, or part thereof.
          </>
        ) : (
          <>Upon publication of your dataset, an invoice will be sent for <b>${dpc}</b>.</>
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
