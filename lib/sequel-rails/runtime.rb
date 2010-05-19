module Rails
  module Sequel
   
    class << self
      def reset_runtime
        @runtime ||= 0
        
        rt, @runtime = @runtime, 0
        rt
      end
    end
    
  end
end