class <%= class_name %><%= options[:parent] ? " < #{options[:parent].classify}" : " < Sequel::Model" %>

end
