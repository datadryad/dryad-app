import React, {useRef, useEffect} from 'react';
import {useStore} from '../../../shared/store';
import ShowCalculations from './ShowCalculations';
import PPRSetting from './PPRSetting';
import SubmitterAgreement from './SubmitterAgreement';

export default function Agreements({
  resource, setResource, user, form, previous, config, setAuthorStep, current = false, preview = false,
}) {
  const {updateStore, storeState: {dpc, refreshFees, userMustPay}} = useStore();
  const subType = resource.resource_type.resource_type;
  const {users} = resource;
  const submitter = users.find((u) => u.role === 'submitter');
  const isSubmitter = user.id === submitter.id;
  const institutionPaying = resource.identifier.display_payer.type === 'StashEngine::Tenant';
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
    if (current || preview) updateStore({refreshDpcStatus: true, refreshFees: true})
  }, [current, preview])

  if (Object.keys(dpc).length === 0) {
    return (
      <p><i className="fas fa-spinner fa-spin" role="img" aria-label="Loading..." /></p>
    );
  }

  return (
    <>
      <PPRSetting {...{resource, setResource, preview, previous}} />
      {preview ? <h2>Do you agree to Dryad’s terms?</h2> : <h3 style={{marginTop: '3rem'}}>Do you agree to Dryad’s terms?</h3>}
      {subType !== 'collection' && (
        <>
          {resource.identifier.display_payer.name && (
            <>
              <div className="callout">
                <p>Payment for this submission is sponsored by <b>{resource.identifier.display_payer.name}</b></p>
              </div>
              {institutionPaying && 
              (previous && resource.tenant_id !== previous.tenant_id) && <p className="del ins">Partner institution changed</p>}
            </>
          )}
          <ShowCalculations {...{resource, config}} key={refreshFees} />
        </>
      )}
      {isSubmitter && (
        <>
          {(subType !== 'collection'
            && (!resource.identifier.payment_type || resource.identifier.payment_type === 'unknown')
            && (userMustPay || institutionPaying)) && (
            <>
              {institutionPaying && !!dpc.aff_tenant && dpc.aff_tenant.id !== resource.tenant_id && (
                <>
                  <p><b>Is this correct?</b> Your author list affiliation <b>{dpc.aff_tenant.long_name}</b> is also a Dryad partner.</p>
                  <div style={{maxWidth: '700px'}} ref={formRef} />
                </>
              )}
              {userMustPay && dpc.unsponsored && 
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
