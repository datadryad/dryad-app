# Institutional partner fees

Academic institutions, independent research organizations, and others partner with Dryad to make our services available to their researchers at a reduced rate. They trust us to provide individualized support to authors, and to curate, publish, and preserve data in the most economical way.

Our institution and research partners also benefit from:

* Time-saving support, training, and outreach — to researchers, colleagues and stakeholders
* Convenient annual billing
* Administrative dashboard — for dataset monitoring and reporting both before and after publication
* Branded instance
* Integration with institutional repositories and integrated library systems (ILS) 

<div class="callout">
  <p style="text-align: center;">Learn more about <a href="/join_us">Dryad services and partner benefits</a></p>
</div>

The annual partner fee is calculated as a total of the anticipated Data Publication Charge (DPC) for the coming year, plus the Annual Service Fee. DPCs are adjusted to reflect actual usage at year-end.

Estimate your organization’s total fees using our fee calculator, or read on for a detailed fee schedule.

<%= render partial: 'fee_calculator/institution' %>

<a href="mailto:partnerships@datadryad.org?subject=Dryad partnership inquiry">Contact us</a> with questions, to discuss partnership, or to confirm the estimated partner fee for your organization.

## Detailed fee schedule

_Effective March 25, 2025_

### Data Publication Charge

The DPC is based on the variable costs of curating, publishing, and preserving one dataset — that is, one package of metadata and data files related to one course of investigation. Pricing is designed to scale with use, with discounts based on volume.

<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout"><th colspan="3" style="text-align: center;">Institutional partner DPC rates for standard-sized (under 10GB) datasets<p style="font-weight: normal; margin: 0 auto">Effective March 25, 2025</p></th></tr>
      <tr>
        <th>DPC tier</th>
        <th>Estimated number of datasets per year</th>
        <th>DPC</th>
      </tr>
    </thead>
    <tbody>
      <%= render partial: 'fee_calculator/table_dpc' %>
    </tbody>
  </table>
</div>
</div>

Datasets larger than 10GB are billed individually as follows. Institutional partners may opt to cover large data fees or assign them to the author.

<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout"><th colspan="2" style="text-align: center;">Institutional partner DPC rates for large (over 10GB) datasets<p style="font-weight: normal; margin: 0 auto">Effective March 25, 2025</p></th></tr>
      <tr>
        <th>Dataset size</th>
        <th>Individual dataset fee</th>
      </tr>
    </thead>
    <tbody>
      <%= render partial: 'fee_calculator/table_ldf' %>
    </tbody>
  </table>
</div>
</div>

### Annual Service Fee

Partners pay a flat Annual Service Fee to help cover Dryad’s fixed costs for service, infrastructure, and operations. Our fixed expenses include: partner support, training, and outreach; operation, maintenance and development of the Dryad platform; financial and legal administration; and leadership, oversight, and strategy development. As a global virtual organization, Dryad does not operate a physical office. Consult our [annual reports](https://github.com/datadryad/governance/tree/main/annual-reports) for details on Dryad expenses.

The annual fee for institutions is based on annual research expenditure.

<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout"><th colspan="3" style="text-align: center;">Institutional partner Annual Service Fee<p style="font-weight: normal; margin: 0 auto">Effective March 25, 2025</p></th></tr>
      <tr>
        <th>Service tier</th>
        <th>Annual research expenditure</th>
        <th>Dryad Annual Service Fee</th>
      </tr>
    </thead>
    <tbody>
      <%= render partial: 'fee_calculator/table_asf', locals: {calc_model: FeeCalculator::InstitutionService.new} %>
    </tbody>
  </table>
</div>
</div>

To promote transparency and equity among our partners Dryad does not offer individual discounts. However, to support growth and development, especially of new data-sharing programs, we offer tiered pricing for three-year agreements, as follows. Three-year agreements are exempt from annual inflationary increases.

<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout"><th colspan="5" style="text-align: center;">Institutional fees for multi-year commitments<p style="font-weight: normal; margin: 0 auto">Effective March 25, 2025</p></th></tr>
      <tr>
        <th rowspan="2">Service tier</th>
        <th rowspan="2">Annual research expenditure (range)</th>
        <th>YR1</th>
        <th>YR2</th>
        <th>YR3+</th>
      </tr>
      <tr>
        <th>50% off</th>
        <th>25% off</th>
        <th>Standard rate</th>
      </tr>
    </thead>
    <tbody>
      <%= render partial: 'fee_calculator/table_myc', locals: {calc_model: FeeCalculator::InstitutionService.new} %>
    </tbody>
  </table>
</div>
</div>

#### Lower- and middle-income countries

Annual Service Fees for institutions based in lower- and middle-income countries are as follows.

<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout"><th colspan="3" style="text-align: center;">Service fees for institutions based in low- and middle-income countries<p style="font-weight: normal; margin: 0 auto">Effective March 25, 2025</p></th></tr>
      <tr>
        <th>Service tier</th>
        <th>Annual research expenditure (range)</th>
        <th>Dryad Annual Service Fee</th>
      </tr>
    </thead>
    <tbody>
      <%= render partial: 'fee_calculator/table_asf', locals: {calc_model: FeeCalculator::InstitutionService.new({low_middle_income_country: true})} %>
    </tbody>
  </table>
</div>
</div>

### Total fees

The DPC and Annual Service Fee are combined to calculate the total annual fee, which can range from $5,000 to $108,250 depending on the institution’s data publications and annual research expenditure.

<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout"><th colspan="6" style="text-align: center;">Sample institutional fee calculation<p style="font-weight: normal; margin: 0 auto">Effective March 25, 2025</p></th></tr>
      <tr>
        <th>Service tier</th>
        <th>Annual Service Fee</th>
        <th>DPC tier</th>
        <th>Datasets published</th>
        <th>DPC fee</th>
        <th>Total annual fees</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>1</td>
        <td>$5,000</td>
        <td>1</td>
        <td>1</td>
        <td>$0</td>
        <td>$5,000</td>
      </tr>
      <tr>
        <td>4</td>
        <td>$30,000</td>
        <td>10</td>
        <td>251</td>
        <td>$30,250</td>
        <td>$60,250</td>
      </tr>
      <tr>
        <td>6</td>
        <td>$50,000</td>
        <td>16</td>
        <td>551</td>
        <td>$58,250</td>
        <td>$108,250</td>
      </tr>
    </tfoot>
  </table>
</div>
</div>


