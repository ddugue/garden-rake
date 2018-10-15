
module Garden
  # Represent something that can be depended upon
  module Dependable
    def each
      return enum_for(:each) unless block_given?
      yield self
    end
  end
end
