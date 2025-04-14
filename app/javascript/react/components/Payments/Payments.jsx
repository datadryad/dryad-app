import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {loadStripe} from '@stripe/stripe-js';
import {EmbeddedCheckoutProvider, EmbeddedCheckout} from '@stripe/react-stripe-js';
import Calculations from '../MetadataEntry/Agreements/Calculations';
import CalculateFees from '../CalculateFees';
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
    if(!invoice) fetchClientSecret();
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
              Instead of paying immediately, I want to generate an invoice for later payment by another entity.{' '}
              <b>
                I understand that this will incur an additional{' '}
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
        Instead of paying immediately, you may generate an invoice for later payment by another entity.{' '}
        <b>An additional administration fee will be charged.</b>{' '}
        <button onClick={() => setInvoice(true)} type="button" className="o-button__plain-textlink" name="get_invoice">
          Continue to the invoice generation form <i className="fas fa-circle-right" aria-hidden="true" />
        </button>
      </p>
    </div>
  );
}

export default Payments;
