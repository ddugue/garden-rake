
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
    if other.is_a? String
      other = [other.format_with_file!]
    end
    @output = other
    self
  end
end
