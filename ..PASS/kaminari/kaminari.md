
kaminari pagination

helper on html and controllers to view pagination
posts per page && next previus posts

add gem
gem 'kaminari', '~> 1.2', '>= 1.2.2'

    bundle install
    
    rails g kaminari:config

creates config/initializers/kaminari_config.rb

config.default_per_page = 25
etc


Kaminari templates

    rails generate kaminari:views default

create  app/views/kaminari/_first_page.html.erb
create  app/views/kaminari/_gap.html.erb
create  app/views/kaminari/_last_page.html.erb
create  app/views/kaminari/_next_page.html.erb
create  app/views/kaminari/_page.html.erb
create  app/views/kaminari/_paginator.html.erb
create  app/views/kaminari/_prev_page.html.erb







  <div class="pagination">
    <%= paginate @records, window: 0, outer_window: 0, left: 0, right: 0 %>
  </div>






  <div class="pagination">
    <%= paginate @records %>
  </div>

</div>


<div class="pagination-wrapper">
  <%= paginate @records %>

  <div class="page-jump">
    <%= form_with url: request.path, method: :get, local: true, class: "jump-form" do |f| %>
      <%# Carry over search and letter filters so the user stays in their results %>
      <%= f.hidden_field :q, value: params[:q] %>
      <%= f.hidden_field :letter, value: params[:letter] %>

      <%= f.number_field :page, placeholder: "Go to page...", min: 1, max: @records.total_pages %>
      <button type="submit">Go</button>
    <% end %>
  </div>
</div>

<div class="pagination-simple">
  <%# .first_page? returns true if you are on page 1 %>
  <% unless @records.first_page? %>
    <%= link_to "← Previous", url_for(page: @records.prev_page), class: "btn" %>
  <% end %>

  <span class="page-info">
    Page <%= @records.current_page %> of <%= @records.total_pages %>
  </span>

<%# .last_page? returns true if there are no more records %>
<% unless @records.last_page? %>
<%= link_to "Next →", url_for(page: @records.next_page), class: "btn" %>
<% end %>
</div>



