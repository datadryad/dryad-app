import React, {useEffect} from 'react';
import axios from 'axios';
import {formatSizeUnits} from '../../lib/utils';
import {ExitIcon} from './ExitButton';

export default function CalculateFees({resource, fees, setFees}) {
  const paid = !!resource.identifier.last_invoiced_file_size;

  const calculateFees = () => {
    axios.get(`/resource_fee_calculator/${resource.id}`, {params: {generate_invoice: true}})
      .then(({data}) => {
        setFees(data.fees);
      });
  };

  useEffect(() => {
    calculateFees();
  }, []);
  /* eslint-disable max-len */
  if (paid) {
    return (
      <>
        <p>This dataset has been previously submitted and the <a href="/requirements#cost" target="blank">{fees.storage_fee_label}<ExitIcon /></a> has been paid for {formatSizeUnits(resource.identifier.last_invoiced_file_size)}.</p>
        {fees.storage_fee ? (
          <p>Since the dataset size has increased to {formatSizeUnits(resource.total_file_size)}, submitting this new version will come with an additional charge of <b>{fees.storage_fee.toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b>.</p>
        ) : null}
      </>
    );
  }

  if (fees.storage_fee) {
    return (
      <p>This {formatSizeUnits(resource.total_file_size)} dataset has a <a href="/requirements#cost" target="blank">{fees.storage_fee_label}<ExitIcon /></a> of <b>{fees.storage_fee.toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b>.</p>
    );
  }
  /* eslint-enable max-len */
  return null;
}
