class <%= class_name %><%= "< #{options[:parent].classify}" if options[:parent] %>

<% unless options[:parent] -%>
  include Sequel::Resource

  property :id, Serial
<% end %>
<% attributes.each do |attribute| -%>
  property :<%= attribute.name -%>, <%= attribute.type_class %>
<% end %>
end
