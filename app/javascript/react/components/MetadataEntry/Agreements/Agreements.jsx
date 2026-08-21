import React, {useRef, useState, useEffect} from 'react';
import {ExitIcon} from '../../ExitButton';
import Calculations from './Calculations';
import CalculateFees, {formatCost} from '../../CalculateFees';
import PPRSetting from './PPRSetting';
import SubmitterAgreement from './SubmitterAgreement';
import {useStore} from '../../../shared/store';

function PaymentMessage({resource, fees}) {
  if (fees.dpc_sponsored) {
    const partner = resource.identifier.display_payer
    const partner_name = Object.hasOwn(partner, 'name') && partner.name || Object.hasOwn(partner, 'title') && partner.title || partner.long_name
    return (
      <>
        <p>
          {fees.total ? 
            'You will be asked to pay this fee upon submission.' : 
            <>All <a href="/costs" target="blank">data publishing fees<ExitIcon/></a> are covered by your sponsorship.</>
          }
        </p>
        <p>
          The total fees are {formatCost(fees.dpc_sponsored + fees.storage_sponsored + fees.storage_fee)}.
          The {partner_name} has sponsored the base Data Publishing Charge ({formatCost(fees.dpc_sponsored)}){
            fees.storage_sponsored ? ` and Large Data Fee (${formatCost(fees.storage_sponsored)})` : ''}.
        </p>
      </>
      // if (Object.hasOwn(partner, 'long_name')) <p>For questions about your sponsorship, please contact {?}</p>
    )
  }

  if (!fees.total) return null

  return (
    <p>
      You will be asked to pay this fee upon submission.
      If you require an invoice to be sent to another entity for payment, an additional administration fee will be charged.
    </p>
  );
}

export default function Agreements({
  resource, setResource, user, form, previous, config, current, setAuthorStep, preview = false,
}) {
  const {updateStore, storeState: {dpc, fees, userMustPay}} = useStore();
  const [ppr, setPPR] = useState(resource.hold_for_peer_review);
  const subType = resource.resource_type.resource_type;
  const {users} = resource;
  const submitter = users.find((u) => u.role === 'submitter');
  const isSubmitter = user.id === submitter.id;
  const formRef = useRef(null);

  useEffect(() => {
    const existing = formRef.current?.querySelector('#dryad-member');
    if (formRef.current && !existing) {
      const active_form = document.createRange().createContextualFragment(form);
      formRef.current.append(active_form);
    }
    if (!!dpc.aff_tenant && existing) {
      formRef.current.querySelector('#dryad-member').hidden = true;
      formRef.current.querySelector('#edit-tenant-form').hidden = false;
      formRef.current.querySelector('#searchselect-tenant__value').value = dpc.aff_tenant.id;
      formRef.current.querySelector('#searchselect-tenant__label').value = dpc.aff_tenant.short_name;
      formRef.current.querySelector('#searchselect-tenant__input').value = dpc.aff_tenant.short_name;
    }
  }, [dpc, formRef.current]);

  useEffect(() => {
    if (preview || current) updateStore({refreshDpcStatus: true});
  }, [current, preview]);

  if (Object.keys(dpc).length === 0) {
    return (
      <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>
    );
  }

  return (
    <>
      <PPRSetting {...{ppr, setPPR, resource, setResource, dpc, preview, previous}} />
      {preview ? <h2>Do you agree to Dryad’s terms?</h2> : <h3 style={{marginTop: '3rem'}}>Do you agree to Dryad’s terms?</h3>}
      {subType !== 'collection' && (
        <>
          {Object.hasOwn(resource.identifier.display_payer, 'name') && (
            <div className="callout">
              <p>Payment for this submission is sponsored by <b>{resource.identifier.display_payer.name}</b></p>
            </div>
          )}
          {Object.hasOwn(resource.identifier.display_payer, 'long_name') && (
            <>
              <div className="callout">
                <p>Payment for this submission is sponsored by <b>{resource.identifier.display_payer.long_name}</b></p>
              </div>
              {previous && resource.tenant_id !== previous.tenant_id && <p className="del ins">Partner institution changed</p>}
            </>
          )}
          {Object.hasOwn(resource.identifier.display_payer, 'title') && (
            <div className="callout">
              <p>Payment for this submission is sponsored by <b>{resource.identifier.display_payer.title}</b></p>
            </div>
          )}
          {resource.identifier.old_payment_system
            ? userMustPay && (
              <>
                <Calculations resource={resource} config={config} />
                <p>The submitter may choose an invoice recipient upon submission of the dataset.</p>
              </>
            )
            : (
              <>
                <CalculateFees resource={resource} fees={fees} ppr={ppr} />
                <PaymentMessage resource={resource} fees={fees} />
              </>
            )}
        </>
      )}
      {isSubmitter && (
        <>
          {(subType !== 'collection'
            && (!resource.identifier.payment_type || resource.identifier.payment_type === 'unknown')
            && (userMustPay || (!dpc.funder_will_pay && dpc.institution_will_pay))) && (
            <>
              {dpc.institution_will_pay && !!dpc.aff_tenant && dpc.aff_tenant.id !== resource.tenant_id && (
                <>
                  <p><b>Is this correct?</b> Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is also a Dryad partner.</p>
                  <div style={{maxWidth: '700px'}} ref={formRef} />
                </>
              )}
              {userMustPay && 
              // Not for LDF payments
              (!dpc.funder_will_pay && !dpc.institution_will_pay && !dpc.journal_will_pay) && 
              (!dpc.aff_tenant || dpc.aff_tenant.id !== resource.tenant_id) && (
                <div className="callout warn" style={{margin: '1em 0', paddingBottom: '5px'}}>
                  <p style={{marginBottom: '.75em'}}>
                    <i className="fas fa-circle-question" aria-hidden="true" style={{marginRight: '.5ch'}} />
                    Are you affiliated with a Dryad partner institution that covers the Data Publishing Charge?
                  </p>
                  <div style={{backgroundColor: 'white', padding: '10px', marginBottom: '5px'}}>
                    {!!dpc.aff_tenant && (
                      <p>
                        Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is a Dryad partner.
                        Verify your credentials for DPC sponsorship.
                      </p>
                    )}
                    {resource.tenant.authentication?.table?.strategy === 'author_match' && (
                      <p style={{marginTop: 0}}>
                        <em>
                          For DPC sponsorship, <b>{resource.tenant.short_name}</b> must appear in your author affiliation list for this submission.
                        </em>{' '}
                        <span
                          style={{whiteSpace: 'nowrap'}}
                          role="button"
                          tabIndex="0"
                          className="o-button__plain-text7"
                          onClick={setAuthorStep}
                          onKeyDown={(e) => {
                            if (['Enter', 'Space'].includes(e.key)) {
                              setAuthorStep();
                            }
                          }}
                        ><i className="fa fa-pencil" aria-hidden="true" style={{marginRight: '.25ch'}} />Edit the author list
                        </span>
                      </p>
                    )}
                    <div style={{maxWidth: '700px'}} ref={formRef} />
                  </div>
                </div>
              )}
            </>
          )}
        </>
      )}
      <SubmitterAgreement {...{preview, isSubmitter, resource, setResource, userMustPay}} />
    </>
  );
}
