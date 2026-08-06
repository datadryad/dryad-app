import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {loadStripe} from '@stripe/stripe-js';
import {EmbeddedCheckoutProvider, EmbeddedCheckout} from '@stripe/react-stripe-js';
import Calculations from '../MetadataEntry/Agreements/Calculations';
import CalculateFees, {formatCost} from '../CalculateFees';
import {ExitIcon} from '../ExitButton';
import InvoiceForm from './InvoiceForm';
import {useStore} from '../../shared/store';


function Receipt({fees}) {
  if (!fees.dpc_sponsored) return null
  return (
    <>
      <p>Your fee breakdown is as follows:</p>
      <div className="table-wrapper" style={{textAlign: 'center'}}>
        <table style={{margin: '0 auto'}}>
          <caption style={{fontSize: '.98rem'}}>All Dryad fees are set on a cost-recovery basis.</caption>
          <thead>
            <tr><td></td><th scope="col">Data Publishing Charge</th><th scope="col">Large Data Fee</th></tr>
          </thead>
          <tbody>
            <tr>
              <th scope="row>">Dryad fees</th>
              <td>{formatCost(fees.dpc_sponsored)}</td>
              <td>{formatCost(fees.storage_fee + fees.storage_sponsored)}</td>
            </tr>
            <tr>
              <th scope="row>">Sponsor credit</th>
              <td>-{formatCost(fees.dpc_sponsored)}</td>
              <td>-{formatCost(fees.storage_sponsored)}</td>
            </tr>
            <tr>
              <th scope="row>">Amount due</th>
              <td></td>
              <td>{formatCost(fees.storage_fee)}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </>
  )
}

function InvoicingPageMessage({fees}) {
  if (fees.dpc_sponsored) {
    return (
      <p>Payment of this fee is due upon receipt of the invoice. You must complete payment to submit your dataset for curation and publication.</p>
    );
  }

  if (fees.invoice_fee) {
    return (
      <>
        <p>You must complete payment to submit your dataset for curation and publication.</p>
        <p>By submitting the following form, you agree:</p>
        <p>
          I want to generate an invoice, due upon receipt, for payment by another entity.{' '}
          <b>
            I understand that this will incur an additional, nonrefundable{' '}
            {formatCost(fees.invoice_fee)} fee.
          </b>
        </p>
      </>
    );
  }

  return null
}

function Payments({
  resource, setResource, invoice, setInvoice, setPayment, config,
}) {
  const {storeState: {fees, dpc}} = useStore();
  const [ppr, setPPR] = useState(resource.hold_for_peer_review);
  const [clientSecret, setClientSecret] = useState(null);
  const stripePromise = loadStripe(config.pk_key);

  const fetchClientSecret = () => {
    axios.post(`/payments/${resource.id}`, {generate_invoice: invoice, pay_ppr_fee: ppr})
      .then(({data}) => {
        setClientSecret(data.clientSecret);
      });
  };

  useEffect(() => {
    if (fees.total && !clientSecret) fetchClientSecret();
  }, [clientSecret]);

  useEffect(() => {
    setClientSecret(null);
  }, [ppr]);

  useEffect(() => {
    if (!invoice) setClientSecret(null);
  }, [invoice]);

  if (invoice) {
    return (
      <div id="submission-payment">
        {resource.identifier.old_payment_system ? <Calculations resource={resource} config={config} /> : (
          <>
            <p>
              <button
                onClick={() => {
                  setClientSecret(null);
                  setInvoice(false);
                }}
                className="o-button__plain-textlink"
                type="button"
              >
                <i className="fas fa-circle-left" aria-hidden="true" /> Back to immediate payment
              </button>
            </p>
            <CalculateFees resource={resource} />
            <Receipt fees={fees} />
            <InvoicingPageMessage fees={fees} />
          </>
        )}
        <InvoiceForm resource={resource} setResource={setResource} setPayment={setPayment} />
      </div>
    );
  }

  return (
    <div id="submission-payment">
      {dpc.can_pay_ppr_fee ? (
        <>
          <CalculateFees resource={resource} ppr />
          <p>You must complete payment to submit your dataset for Peer Review.</p>
          <p className="input-line" style={{justifyContent: 'center'}} role="group" aria-label="Choose payment">
            <button
              type="button"
              className="submit-toggle"
              aria-current={ppr === false}
              aria-controls="payment-sec"
              aria-disabled={ppr === false || null}
              onClick={() => setPPR(false)}
              style={{flex: 1}}
            >
              Pay full {fees?.storage_fee?.toLocaleString('en-US', {style: 'currency', currency: 'USD'})} now
            </button>
            <button
              type="button"
              className="submit-toggle"
              aria-current={ppr}
              aria-controls="payment-sec"
              aria-disabled={ppr || null}
              onClick={() => setPPR(true)}
              style={{flex: 1}}
            >
              Pay $50.00 Peer Review Fee
            </button>
          </p>
        </>
      ) : (
        <>
          <CalculateFees resource={resource} />
          <Receipt fees={fees} />
          <p>You must complete payment to submit your dataset for curation and publication.</p>
        </>
      )}
      <div id="payment-sec" hidden={(dpc.can_pay_ppr_fee && ppr === null) || null}>
        {clientSecret ? (
          <EmbeddedCheckoutProvider
            stripe={stripePromise}
            options={{clientSecret}}
          >
            <EmbeddedCheckout />
          </EmbeddedCheckoutProvider>
        ) : (
          <p style={{textAlign: 'center', color: '#888'}}><i className="fa fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>
        )}
        {!ppr && (
          <>
            <p style={{fontWeight: 'bold'}} role="heading" aria-level="2">Need an invoice?</p>
            <p>
              If your organization requires an invoice to be sent to a specific email address, one may be generated.
              {fees.dpc_sponsored ? '' : <> <b>An additional, nonrefundable administration fee will be charged for this service.</b> </>}
              <button onClick={() => setInvoice(true)} type="button" className="o-button__plain-textlink" name="get_invoice" style={{paddingLeft: 0}}>
                Continue to the invoice generation form <i className="fas fa-circle-right" aria-hidden="true" />
              </button>
            </p>
          </>
        )}
      </div>
      <br />
      <p style={{fontSize: '.98rem', textAlign: 'center'}}>
        <a href="/costs" target="_blank">All about the Data Publishing Charge, payment methods, and refund policies<ExitIcon /></a>
      </p>
    </div>
  );
}

export default Payments;
