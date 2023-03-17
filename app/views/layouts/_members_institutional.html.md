<ul class="member-list">
  <% orgs = StashEngine::Tenant.partner_list.map{ |t| t.long_name } + APP_CONFIG.funder_exemptions %>
  <% orgs.sort.each do |o| %>
    <li>
      <span><%= o %></span>
    </li>
  <% end %>
</ul>