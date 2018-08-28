##
# Small data structure to pass Arguments to an SH Command
class Args
  attr_reader :input
  attr_reader :command
  attr_reader :output

  def initialize(input, cmd)
    @input = input || nil
    @command = cmd
  end

  def >>(other)
    other = [other.format_with_file!] if other.is_a? String
    @output = other
    self
  end
end
