
module Garden
  ##
  # Task that does nothing
  ##
  class Noop < Rake::Task
    def initialize( app)
      super "noop", app
    end
    def invoke_with_call_chain(*args)
      nil
    end
  end
end
