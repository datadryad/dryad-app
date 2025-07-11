import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {loadStripe} from '@stripe/stripe-js';
import {EmbeddedCheckoutProvider, EmbeddedCheckout} from '@stripe/react-stripe-js';
import Calculations from '../MetadataEntry/Agreements/Calculations';
import CalculateFees from '../CalculateFees';
import {ExitIcon} from '../ExitButton';
import InvoiceForm from './InvoiceForm';

function Payments({
  resource, setResource, setPayment, config,
}) {
  const [fees, setFees] = useState({});
  const [invoice, setInvoice] = useState(resource.identifier.old_payment_system);
  const [clientSecret, setClientSecret] = useState(null);

  const stripePromise = loadStripe(config.pk_key);

  const fetchClientSecret = () => {
    axios.post(`/payments/${resource.id}`, {generate_invoice: invoice})
      .then(({data}) => {
        setClientSecret(data.clientSecret);
      });
  };

  useEffect(() => {
    if (!invoice) fetchClientSecret();
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
            <CalculateFees resource={resource} fees={fees} setFees={setFees} invoice={invoice} />
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
        <InvoiceForm resource={resource} setResource={setResource} setPayment={setPayment} fees={fees} />
      </div>
    );
  }

  return (
    <div id="payment">
      <CalculateFees resource={resource} fees={fees} setFees={setFees} invoice={invoice} />
      <p>You must complete payment to submit your dataset for curation and publication.</p>
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
      <p style={{fontWeight: 'bold'}} role="heading" aria-level="2">Need an invoice?</p>
      <p>
        If your organization requires an invoice to be sent to a specific email address, one may be generated.{' '}
        <b>An additional, nonrefundable administration fee will be charged for this service.</b>{' '}
        <button onClick={() => setInvoice(true)} type="button" className="o-button__plain-textlink" name="get_invoice">
          Continue to the invoice generation form <i className="fas fa-circle-right" aria-hidden="true" />
        </button>
      </p>
      <br />
      <p style={{fontSize: '.98rem', textAlign: 'center'}}>
        <a href="/costs" target="_blank">All about the Data Publishing Charge, payment methods, and refund policies<ExitIcon /></a>
      </p>
    </div>
  );
}

export default Payments;
