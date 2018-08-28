require 'rake/garden/command'

module Garden
  ##
  # Command that sets an environment variable
  # We mostly create a command for logging purpose
  class SetCommand < Command
    ##
    # Convert args to a dictionary
    def to_dict(args)
      if args.length > 1
        # first arg is a symbol, second is value
        { args[0] => args[1] }
      elsif args.length == 1
        # first arg is already a dict, we convert to string
        raise 'Set argument must be an hash' unless args[0].is_a? Hash
        args[0]
      else
        raise 'Invalid syntax for set. Please see docs'
      end
    end

    ##
    # Convert all key and values to string
    def dict_to_s(dict)
      Hash[dict.map { |k, v| [k.to_s, v.to_s] }]
    end

    def initialize(task, *args)
      @dict = dict_to_s(to_dict(args))
      task.env.merge! @dict
      super
    end

    def to_s
      arr = @dict.to_a
      "Setting up flag #{arr[0][0]} to #{arr[0][1]}"
    end
  end
end
