require 'ostruct'
require 'singleton'

module Garden
  # Represent a global context object which enables to set global values and
  # thus transcend the block available values
  # TODO: Make context dependant on thread
  class Context < OpenStruct
    include Singleton

    # Set the global propriety +symbol+
    def with_value(symbol, value)
      previous = self[symbol]
      self[symbol] = value if value
      yield
      self[symbol] = previous
    end
  end
end
