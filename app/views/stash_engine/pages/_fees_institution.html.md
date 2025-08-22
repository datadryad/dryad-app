# Institutional partner fees

_Effective March 25, 2025_

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

The annual partner fee is calculated as a total of the anticipated [Data Publishing Charge (DPC)](#data-publication-charge) for the coming year, plus the [Annual Service Fee](#annual-service-fee). DPCs are adjusted to reflect actual usage at year-end.

Estimate your organization’s total fees using our fee calculator, or read on for a detailed fee schedule.

<div hidden>

## Fee calculator

</div>

<%= render partial: 'fee_calculator/institution' %>

<a href="mailto:partnerships@datadryad.org?subject=Dryad partnership inquiry">Contact us</a> with questions, to discuss partnership, or to confirm the estimated partner fee for your organization.

## Data Publishing Charge

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

## Annual Service Fee

Partners pay a flat Annual Service Fee to help cover Dryad’s fixed costs for service, infrastructure, and operations. Our fixed expenses include: partner support, training, and outreach; operation, maintenance and development of the Dryad platform; financial and legal administration; and leadership, oversight, and strategy development. As a global virtual organization, Dryad does not operate a physical office. Consult our [annual reports](https://github.com/datadryad/governance/tree/main/annual-reports) for details on Dryad expenses.

The annual fee for institutions is based on annual research expenditure as defined by relevant higher education research and development surveys and statistics worldwide (e.g. in the US, the [National Center for Science and Engineering Statistics](https://ncses.nsf.gov/surveys/higher-education-research-development/2023#data); in Australia, the [Australian Bureau of Statistics](https://www.abs.gov.au/statistics/industry/technology-and-innovation/research-and-experimental-development-higher-education-organisations-australia/latest-release#:~:text=Expenditure%20on%20R%26D%20performed%20by,5%25%20in%20chain%20volume%20terms.), etc.). That usually encompasses all current and capital funds allocated to activities specifically organized to produce research outcomes, including funding from external sponsors (government agencies, industry, foundations) as well as institutional resources dedicated to research activities.

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

For campus-based publishers where both the library and the press are Dryad partners, we levy a single Annual Service Fee paid by the institution based on research expenditure. Each entity is responsible for the Data Publishing Charges for their respective authors.

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

## Lower- and middle-income countries

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

## Consortium offers

Our consortial fee structures reflect the reduction in administrative burden and recruitment benefit that consortia can provide. Annual Service Fees are discounted to reflect that savings and benefit, and scale with the number of participating institutions.


<div style="text-align: center;">
<div class="table-wrapper" role="region" tabindex="0" style="margin: 0 auto">
  <table style="width: 100%;">
    <caption>
      All fees are listed in USD
    </caption>
    <thead>
      <tr class="callout">
        <th colspan="2" scope="row" style="text-align: right;">Number of participating institutions</th>
        <td>5-10</td><td>11-25</td><td>26+</td>
      </tr>
      <tr class="callout alt">
        <th colspan="2" scope="row" style="text-align: right;">Discount</th>
        <td>10%</td><td>15%</td><td>20%</td>
      </tr>
      <tr>
        <th scope="col">Service tier</th>
        <th scope="col">Base fee</th>
        <th colspan="3" scope="col">Discounted Annual Service Fee</th>
      </tr>
    </thead>
    <tbody>
      <% tiers = FeeCalculator::InstitutionService.new.service_fee_tiers %>
      <% tiers.each do |t| %>
        <tr>
          <td><%= t[:tier]%></td>
          <td><%= number_to_currency(t[:price], precision: 0) %></td>
          <td><%= number_to_currency(t[:price] - t[:price] * 0.1, precision: 0) %></td>
          <td><%= number_to_currency(t[:price] - t[:price] * 0.15, precision: 0) %></td>
          <td><%= number_to_currency(t[:price] - t[:price] * 0.2, precision: 0) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
</div>


Discounts are dependent on centralized billing arranged by the consortium. Separate Data Publication Charges and Large Data Fees (optional) apply, and are also billed to the consortium.

Consortium discounts are applied after pro-ration for institutions joining part-way through the year, and after any applicable multi-year discounting.

Colleagues interested in a consortium-level partnership are invited to please <a href="mailto:partnerships@datadryad.org?subject=Dryad partnership inquiry">contact us</a>.


## Total fees

The DPC and Annual Service Fee are combined to calculate the total annual fee, which can range from $5,000 to $108,250 USD depending on the institution’s data publications and annual research expenditure.

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

<div style="font-size: .98rem;">
<h3 style="font-size: 1.1rem">Change log</h3>
<ul>
  <li>August 28, 2025: Added detailed description of annual research expenditures</li>
  <li>June 24, 2025: Added consortium policy and pricing table</li>
  <li>June 18, 2025: Clarified policy for cases where both an institutional library and a campus-based publisher have partner agreements</li>
  <li>May 15, 2025: Applied the format ‘$100 USD’ to prices that appear in text and included the phrase ‘All fees are listed in USD’ with all relevant tables
</ul>