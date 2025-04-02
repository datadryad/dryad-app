import React, {useState, useEffect} from 'react';
import axios from 'axios';
import {loadStripe} from '@stripe/stripe-js';
import {EmbeddedCheckoutProvider, EmbeddedCheckout} from '@stripe/react-stripe-js';

const Payments = ({ resource, config }) => {
  const [fees, setFees] = useState({});
  const [requireInvoice, setRequireInvoice] = useState(false);
  const [clientSecret, setClientSecret] = useState(false);

  window.stripePromise ||= loadStripe(config.pk_key);
  useEffect(() => {
    calculateFees()
    fetchClientSecret()
  }, [requireInvoice]);

  const humanizeString = (str) => {
    return str
      .replace(/_/g, " ")          // Replace underscores with spaces
      .replace(/([a-z])([A-Z])/g, "$1 $2") // Add space before capital letters
      .replace(/\b\w/g, (char) => char.toUpperCase()); // Capitalize first letters
  };

  const calculateFees = () => {
    axios.get(`/resource_fee_calculator/${resource.id}`, { params: { generate_invoice: requireInvoice } })
      .then(({data}) => {
        setFees(data.fees)
      })
  }

  const fetchClientSecret = () => {
    axios.post(`/payments/${resource.id}`, { generate_invoice: requireInvoice })
      .then(({data}) => {
        setClientSecret(data.clientSecret)
      })
  }

  const handleRequireInvoice = (event) => {
    setRequireInvoice(event.target.checked);
  }

  const FeeRow = ({ feeKey }) => {
    const value = fees[feeKey]

    if (value === 0) return <></>;

    return (
      <tr>
        <td>{humanizeString(feeKey)}</td>
        <td>${value}</td>
      </tr>
    )
  }

  const CheckoutForm = () => {
    return (
      <div id="checkout">
        <EmbeddedCheckoutProvider
          stripe={window.stripePromise}
          options={{ clientSecret }}
        >
          <EmbeddedCheckout />
        </EmbeddedCheckoutProvider>
      </div>
    )
  }

  return (
    <div>
      <h3>Payment</h3>
      {fees.total > 0 &&
        <>
          <label>Require Invoice: </label>
          <input type="checkbox" onChange={handleRequireInvoice} />
        </>
      }
      <table width="100%">
        {Object.keys(fees).map(feeKey => <FeeRow feeKey={feeKey} key={feeKey} />)}
      </table>
      <div>
        <CheckoutForm />
      </div>
    </div>
  )
}

export default Payments;
