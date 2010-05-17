module Rails
  module Sequel

    module I18nSupport
      # Set the i18n scope to overwrite ActiveModel.
      def i18n_scope #:nodoc:
        :sequel
      end
    end

  end
end
