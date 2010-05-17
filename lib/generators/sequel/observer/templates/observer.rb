class <%= class_name %>Observer

  include Sequel::Observer

  observe <%= class_name %>

end
