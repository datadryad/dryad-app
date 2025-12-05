import React from 'react';
import {formatSizeUnits} from '../../lib/utils';
import {ExitIcon} from './ExitButton';
import {useStore} from '../shared/store';

export default function CalculateFees({resource, ppr = false}) {
  const {storeState: {fees} } = useStore();
  const paid = !!resource.identifier.last_invoiced_file_size;

  /* eslint-disable max-len */
  if (paid && fees.storage_fee_label) {
    return (
      <>
        <p>This dataset has been previously submitted and the <a href="/costs" target="blank">{fees.storage_fee_label}<ExitIcon /></a> has been paid for {formatSizeUnits(resource.identifier.last_invoiced_file_size)}.</p>
        {fees.total ? (
          <p>Since the dataset size has increased to {formatSizeUnits(resource.total_file_size)}, submitting this new version will come with an additional charge of <b>{fees.storage_fee.toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b>.</p>
        ) : null}
      </>
    );
  }

  if (ppr && fees.ppr_discount) {
    return (
      <p>The <b>{(50).toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b> Private for Peer Review Fee has been paid. The remainder of the <a href="/costs" target="blank">{fees.storage_fee_label}<ExitIcon /></a> is due at submission for curation and publication.</p>
    );
  }

  if (fees.total && fees.storage_fee) {
    return (
      <>
        <p>This {formatSizeUnits(resource.total_file_size)} dataset has a <a href="/costs" target="blank">{fees.storage_fee_label}<ExitIcon /></a> of <b>{fees.storage_fee.toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b>{fees.ppr_discount && <>, requiring payment of <b>{(fees.invoice_fee ? fees.total - fees.invoice_fee : fees.total).toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b> minus the Private for Peer Review Fee</>}.</p>
        {ppr && !fees.ppr_discount && <p>You may choose to pay only <b>{(50).toLocaleString('en-US', {style: 'currency', currency: 'USD'})}</b>, with the remainder due at the end of the peer review period. The Private for Peer Review Fee is nonrefundable.</p>}
      </>
    );
  }

  /* eslint-enable max-len */
  return null;
}
