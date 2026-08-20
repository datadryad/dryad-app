<% @page_title = 'Authors and editors' %>
<h1>Authors and editors</h1>

All contributing authors should be entered, and editors may be invited to collaborate, from the **Authors** step of the submission checklist.


## Entering author information

When you create a Dryad submission, the name and email address from [your Dryad account](/help/account/management) will automatically be added as the first author at the **Authors** step of the submission checklist. 

Your Dryad submission should include the full list of contributors to the collection or analysis of the data. This is often the same list of authors included in the primary publication citing your data. If you have such a publication, [an existing author list can be imported](/help/submission_steps/connect).

The author list can be reordered with a drag-and-drop mechanism.

### Required fields

The name and at least one institutional affiliation are required for each author in the author list of your submission. Institutional affiliations are retrieved from [ROR](https://ror.org/) (Research Organization Registry), and can be searched by name or by ROR ID URL (for example, [https://ror.org/00x6h5n95](https://ror.org/00x6h5n95)). Institution names not found on ROR can also be entered.

Email addresses may be included for all authors, and are required for collaboration on the submission. At least one email address is required to be displayed on the public dataset page, for the data’s corresponding author.


## Collaborating on a data submission

Any authors in the author list may be invited to collaborate on the submission. Collaborators may edit all of the submission metadata and add or adjust files.

The creator or the submitter of the data may invite other authors to become collaborators from the **Authors** step of the submission checklist. After entering author information, including an email address, you may click the *Invite to edit* button at the bottom right of any author block.

One collaborator must be selected as the submitter. The submitter has several important responsibilities:


* When collaborators are satisfied and the data is complete, the submitter must review and submit the data
* If the dataset is not sponsored by a journal, the submitter must pay, or be affiliated with an institution that sponsors, the [Data Publishing Charge](/costs)
* The submitter receives any notifications from Dryad, including any revision requests during curation

The creator of the submission may select another author to be the submitter. If the submitter needs to be changed again after this selection is made, please contact the helpdesk.

Only one collaborator may actively work on a submission at a time. To save your work and allow other collaborators to access the editor, click **Save & exit** from within the submission editor, or on the dataset listing on your [My datasets](/dashboard) page. If you are unable to edit a submission because the current editor is unresponsive, please contact the helpdesk.


## Recognizing author contributions

Different authors play different roles in the generation, curation, and publication of a dataset. To accurately recognize and share these varied contributions, we use an adapted list of [CRediT](https://credit.niso.org) roles that incorporates a [GREI-recommended subset for generalist repositories](https://zenodo.org/records/16953589). We ask that each author select one or more from a list of possible options.

While we encourage use of this functionality, we do not mandate it. However, should a role for any author be selected, then at least one role is required for each author of the same dataset. It is the submitter's responsibility to ensure the accuracy of all authors' roles.

Where supplied, contribution roles are then presented in the "Author information" section on the dataset landing page.

### Role definitions

<dl id="credit-defs">
<% StashDatacite::CreditRole.all.map do |cr| %>
  <div>
    <dt><%= cr.credit_role %></dt>
    <dd><%= cr.description %></dd>
  </div>
<% end %>
</dl>
