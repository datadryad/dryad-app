import React from 'react';
import {formatSizeUnits} from '../../../../lib/utils';
import {useStore} from '../../../shared/store';
import {ExitIcon} from '../../ExitButton';
import CalculateFees, {formatCost} from '../../CalculateFees';
import Calculations from './Calculations';

function PaymentMessage({resource, fees}) {
  if (fees.dpc_sponsored) {
    const partner = resource.identifier.display_payer
    return (
      <>
        <p>
          {fees.total ? 
            'You will be asked to pay this fee upon submission.' : 
            <>All <a href="/costs" target="blank">data publishing fees<ExitIcon/></a> are covered by your sponsorship.</>
          }
        </p>
        {!resource.identifier.last_invoiced_file_size &&
          <p>
            The total fees are {formatCost(fees.dpc_sponsored + fees.storage_sponsored + fees.storage_fee)}.
            The {partner.name} has sponsored the base Data Publishing Charge ({formatCost(fees.dpc_sponsored)}){
              fees.storage_sponsored ? ` and Large Data Fee (${formatCost(fees.storage_sponsored)})` : ''}.
            {partner.contact &&
              <> For questions about your sponsorship, please contact <a href={`mailto:${partner.contact}`}>{partner.contact}</a>.</>
            }
          </p>
        }
      </>
    )
  }

  if (!fees.total) {
    if (fees.ppr_warning) {
      return (
        <p>
         There may be an additional <a href="/costs" target="blank">{
            fees.storage_fee_label
          }<ExitIcon /></a> to be paid when your {formatSizeUnits(resource.total_file_size)} dataset leaves Private for Peer Review status.
        </p>
      )
    } else return null
  }

  return (
    <p>
      You will be asked to pay this fee upon submission.
      If you require an invoice to be sent to another entity for payment, an additional administration fee will be charged.
    </p>
  );
}

export default function ShowCalculations({resource, ppr, config}) {
  const {storeState: {fees, refreshFees, userMustPay}} = useStore();
  if (resource.identifier.old_payment_system) {
    if (userMustPay) {
      return (
        <>
          <Calculations resource={resource} config={config} />
          <p>The submitter may choose an invoice recipient upon submission of the dataset.</p>
        </>
      )
    }
    return null
  }

  if (refreshFees) {
    return (
      <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>
    );
  }

  return (
    <>
      <CalculateFees resource={resource} fees={fees} ppr={ppr} />
      <PaymentMessage resource={resource} fees={fees} />
    </>
  )
}