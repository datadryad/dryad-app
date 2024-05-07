<ul class="member-list">
  <% orgs = StashEngine::Tenant.partner_list.map(&:long_name) + StashEngine::Funder.exemptions.map(&:name) %>
  <% orgs.sort.each do |o| %>
    <li><%= o %></li>
  <% end %>
</ul>