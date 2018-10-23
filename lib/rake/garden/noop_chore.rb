# frozen_string_literal: true

require 'rake/garden/chore'

module Garden
  ##
  # Task that does nothing
  class NoopChore < Chore
    def initialize(app)
      super 'noop', app
    end

    def invoke_with_call_chain(*)
      nil
    end
  end
end
