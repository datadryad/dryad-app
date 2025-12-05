import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {loadStripe} from '@stripe/stripe-js';
import {EmbeddedCheckoutProvider, EmbeddedCheckout} from '@stripe/react-stripe-js';
import Calculations from '../MetadataEntry/Agreements/Calculations';
import CalculateFees from '../CalculateFees';
import {ExitIcon} from '../ExitButton';
import InvoiceForm from './InvoiceForm';
import {useStore} from '../../shared/store';

function Payments({
  resource, setResource, invoice, setInvoice, setPayment, config,
}) {
  const {storeState: {fees} } = useStore();
  const [ppr, setPPR] = useState(null);
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
      <div id="payment">
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
            <p>By submitting the following form, you agree:</p>
            <p>
              I want to generate an invoice, due upon receipt, for payment by another entity.{' '}
              <b>
                I understand that this will incur an additional, nonrefundable{' '}
                {fees?.invoice_fee?.toLocaleString('en-US', {style: 'currency', currency: 'USD', maximumFractionDigits: 0})} fee.
              </b>
            </p>
          </>
        )}
        <InvoiceForm resource={resource} setResource={setResource} setPayment={setPayment} />
      </div>
    );
  }

  return (
    <div id="payment">
      {resource.hold_for_peer_review ? (
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
          <p>You must complete payment to submit your dataset for curation and publication.</p>
        </>
      )}
      <div id="payment-sec" hidden={(resource.hold_for_peer_review && ppr === null) || null}>
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
            If your organization requires an invoice to be sent to a specific email address, one may be generated.{' '}
              <b>An additional, nonrefundable administration fee will be charged for this service.</b>{' '}
              <button onClick={() => setInvoice(true)} type="button" className="o-button__plain-textlink" name="get_invoice">
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
