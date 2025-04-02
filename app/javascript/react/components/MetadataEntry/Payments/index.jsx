import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {loadStripe} from '@stripe/stripe-js';
import {EmbeddedCheckoutProvider, EmbeddedCheckout} from '@stripe/react-stripe-js';

function Payments({resource, config}) {
  const [fees, setFees] = useState({});
  const [requireInvoice, setRequireInvoice] = useState(false);
  const [clientSecret, setClientSecret] = useState(false);

  window.stripePromise ||= loadStripe(config.pk_key);

  const humanizeString = (str) => str
    .replace(/_/g, ' ') // Replace underscores with spaces
    .replace(/([a-z])([A-Z])/g, '$1 $2') // Add space before capital letters
    .replace(/\b\w/g, (char) => char.toUpperCase()); // Capitalize first letters

  const calculateFees = () => {
    axios.get(`/resource_fee_calculator/${resource.id}`, {params: {generate_invoice: requireInvoice}})
      .then(({data}) => {
        setFees(data.fees);
      });
  };

  const fetchClientSecret = () => {
    axios.post(`/payments/${resource.id}`, {generate_invoice: requireInvoice})
      .then(({data}) => {
        setClientSecret(data.clientSecret);
      });
  };

  const handleRequireInvoice = (event) => {
    setRequireInvoice(event.target.checked);
  };

  useEffect(() => {
    calculateFees();
    fetchClientSecret();
  }, [requireInvoice]);

  return (
    <div>
      <h3>Payment</h3>
      {fees.total > 0
        && (
          <>
            <label htmlFor="invoice_req">Require Invoice: </label>
            <input type="checkbox" id="invoice_req" onChange={handleRequireInvoice} />
          </>
        )}
      <table width="100%">
        {Object.keys(fees).map((feeKey) => {
          const value = fees[feeKey];
          if (value === 0) return null;
          return (
            <tr>
              <td>{humanizeString(feeKey)}</td>
              <td>${value}</td>
            </tr>
          );
        })}
      </table>
      <div id="checkout">
        <EmbeddedCheckoutProvider
          stripe={window.stripePromise}
          options={{clientSecret}}
        >
          <EmbeddedCheckout />
        </EmbeddedCheckoutProvider>
      </div>
    </div>
  );
}

export default Payments;
