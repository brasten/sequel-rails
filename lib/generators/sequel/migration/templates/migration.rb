class <%= migration_file_name.camelize %>Migration < Sequel::Migration

  def up
    create_table :<%= table_name %> do
      primary_key :id
<% attributes.each do |attribute| -%>
      <%= attribute.type_class %> :<%= attribute.name %>
<% end -%>
    end
  end

  def down
    drop_table :<%= table_name %>
  end

end
