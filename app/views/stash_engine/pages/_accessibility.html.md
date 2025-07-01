# Accessibility

*Updated: May 20, 2025*

This accessibility statement applies to [datadryad.org](https://datadryad.org/) and its subdomain [blog.datadryad.org](https://blog.datadryad.org/).

Dryad is committed to making our website accessible to everyone, including individuals with disabilities.

Our website is built to be accessible via screen readers, keyboard navigation, and mobile devices. Older, legacy pages may not meet these standards yet, but we are working to update them on an ongoing basis. We conduct accessibility tests continuously as we develop new features or refine existing ones.

Dryad has a [Voluntary Product Accessibility Template](/docs/DryadVPAT.pdf) (VPAT), assessing conformance with Web Content Accessibility Guidelines 2.2. 

Dataset files are shared on the Dryad platform in a variety of formats. Not all data files and formats will be accessible to users who use screen readers or other assistive technologies.

## Report an accessibility problem

If you have trouble using the Dryad website or blog or accessing our content, please let us know. Send us an email using the form below, and we will do our best to provide the information you are seeking as soon as we can.

<div id="contact_form" aria-live="polite">
<%= form_with(url: stash_url_helpers.contact_helpdesk_path, method: :post, local: false, id: 'accessibility-email') do |form| %>
  <%= form.hidden_field :subject, value: 'Accessibility issue report' %>
  <%= form.hidden_field :body %>
  <div class="c-input__inline">
    <div class="c-input">
      <%= form.label :sname, "Your full name:", class: 'c-input__label' %>
      <%= form.text_field :sname, class: 'c-input__text', autocomplete: 'name', required: true, value: current_user ? "#{current_user&.first_name} #{current_user&.last_name}" : '' %>
    </div>
    <div class="c-input">
      <%= form.label :email, "Your email address:", class: 'c-input__label' %>
      <%= form.email_field :email, required: true, class: 'c-input__text', autocomplete: 'email', value: current_user&.email %>
    </div>
  </div>
  <div class="c-input">
    <label for="url" class="c-input__label--required">URL of the specific web page or content you tried to access</label>
    <input class="c-input__text" required="required" type="text" name="url" id="url"/>
  </div>
  <div class="c-input">
    <label for="report" class="c-input__label--required">Please describe the accessibility problem you experienced</label>
    <textarea class="c-input__textarea" style="width:100%" rows="5" required="required" name="report" id="report"></textarea>
  </div>
  <p style="display: flex; align-items: baseline; justify-content: space-between; flex-wrap: wrap; gap: 2ch">
    <span style="color: rgb(209, 44, 29);">* Fields are required</span>
    <button type="submit" class="o-button__plain-text1">Report problem</button>
  </p>
<% end %>
</div>
