require 'rake/garden/command'

module Garden
  ##
  # Command that sets an environment variable
  # We mostly create a command for logging purpose
  class SetCommand < Command
    def initialize(task, *args)
      if args.length > 1
        # first arg is a symbol, second is value
        @dict = {args[0].to_s => args[1].to_s}
      elsif args.length == 1
        # first arg is a dict
        raise "Set argument must be an hash" if not args[0].is_a? Hash
        @dict = Hash[args[0].map { |k, v| [k.to_s, v.to_s] }]
      else
        raise 'Invalid syntax for set. Please see docs'
      end

      task.env.merge! @dict
      super()
    end

    def to_s
      a = @dict.to_a
      "Setting up flag #{a[0][0]} to #{a[0][1]}"
    end
  end
end
