require 'rake/garden/command_args'

class Array
  def format_with_file!
    self.map(&:format_with_file!)
  end

  def >>(other)
    Args.new self.format_with_file!, other.format_with_file!
  end
end
