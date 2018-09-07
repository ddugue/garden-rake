require 'pathname'
require 'open3'
require 'colorize'
require 'ostruct'
# require 'stackprof'
class Group
  attr_accessor :array
  attr_accessor :prefix

  def initialize(arr=nil, delimiter='')
    @delimiter = delimiter
    @array = arr
  end

  def end_delimiter
    case @delimiter
    when '[' then ']'
    when '(' then ')'
    when '{' then '}'
    when '"' then '"'
    when "'" then "'"
    else ''
    end
  end

  def separator
    @delimiter == '"' || @delimiter == "'" ? '' : ','
  end

  def to_s
    "#{prefix}#{@delimiter}#{@array.map(&:to_s).join(separator)}#{end_delimiter}"
  end

  ##
  # Override of the default methods to access data
  def [](ind)
    @array[ind]
  end

  def []=(ind, value)
    @array[ind] = value
  end

  def key?(key)
    @array.key? key
  end

  def fetch(value, default)
    @array.fetch(value, default)
  end

  def to_a
    @array
  end
end

class ArgParser
  DELIMITERS = Set.new(['[', '(', '{', '"', "'"])

  attr_reader :index

  def initialize(str, starting_index=0)
    @chars = str
    @chars = @chars.each_char.to_a if @chars.is_a? String
    @index = starting_index
  end

  def pop_stack(stack)
    res = stack.reverse.join.strip
    stack.clear
    res
  end

  def parse(delimiter="(")
    g = Group.new(nil, delimiter)
    @index += 1
    c = @chars[@index]
    args = []
    stack = []
    until c == g.end_delimiter || @index >= @chars.length
      if DELIMITERS.include?(c)
        sub = parse(c)
        sub.prefix = pop_stack stack
        args.unshift sub
      elsif c == ','
        s = pop_stack stack
        args.unshift s unless s == ''
      else
        stack.unshift c
      end
      @index += 1
      c = @chars[@index]

    end
    args.unshift(pop_stack stack) unless stack.empty?
    g.array = args.reverse
    g
  end

  def args
    @args ||= parse
  end

  def readfile
    nil
  end

  def writefile
    nil
  end
end

class OpenAtArgs < ArgParser
  def flags
    args[2]
  end

  def path
    args[1].to_a.join
  end

  def write?
    return nil if flags.include? "O_DIRECTORY"
    flags.include? "O_WRONLY" or flags.include? "O_RDWR"
  end

  # Return wether the syscall read from a file
  def readonly?
    return nil if flags.include? "O_DIRECTORY"
    flags.include? "O_RDONLY"
  end

  def readfile
    readonly? ? path : nil
  end

  def writefile
    write? ? path : nil
  end
end

class RenameArgs < ArgParser
  def readfile
    args[0].to_a.join
  end

  def writefile
    args[1].to_a.join
  end
end


NUMBERS = Set.new([' ', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
class StraceLineParser
  PARSERS = {
    "openat" => OpenAtArgs,
    "rename" => RenameArgs
  }

  def initialize(line, default_pid=nil)
    @line = line.split('')
    @index = 0
    @default_pid = default_pid
  end

  def parse_pid
    start = @index
    @index += 1 while NUMBERS.include? @line[@index]
    start != @index ? @line[start..@index - 1].join.strip : @default_pid
  end

  def pid
    @pid ||= parse_pid
  end

  def parse_fn
    return "" if (@line[@index] == "+" || @line[@index] == "-")
    start = @index
    @index += 1 until @line[@index] == "("
    @line[start..@index - 1].join
  end

  def fn
    return "" unless pid
    @fn ||= parse_fn
  end

  def args
    return nil unless PARSERS.include? fn
    @args ||= PARSERS[fn].new(@line, @index)
  end

  def result
    return nil unless args
    @result ||= @line[args.index+1..-1].join
  end
end

module Garden
  class StraceCommand < ShCommand
    IGNORE_PATTERNS = [
      Regexp.new('^/usr'),
      Regexp.new('^/etc'),
      Regexp.new('^/dev'),
      Regexp.new('^/proc'),
      Regexp.new('node_modules/'),
      Regexp.new('site-packages/'),
      Regexp.new('__pycache__'),
      Regexp.new('\.so$')
    ]

    def result_path
      @result_path ||= "/tmp/#{@orig_command.hash}"
    end

    def initialize(cmd)
      @orig_command = cmd.format_with_file!
      @calls = Array.new

      @stats = {} # For debug purposes
      @debug = $DEBUG || false

      @metadata = metadata.namespace(@orig_command)

      super "strace -qq -f -e trace=open,rename,openat -o #{result_path} #{@orig_command}"
      @input = @metadata.fetch("inputs", [])
      @output = @metadata.fetch("outputs", [])
    end

    def save_results
      @metadata["env"] = @env
      @metadata["inputs"] = input_files
      @metadata["outputs"] = output_files
    end

    def skip?
      if @skip.nil?
        @skip = false if @metadata.fetch("env", nil) != @env
      end
      super
    end

    def on_complete
      super
      strace
      save_results
    end

    def strace
      @stream = File.open result_path, "r"
      @stream.each do |line|
        stracer = StraceLineParser.new line, @thread.pid
        @stats[stracer.fn] = @stats.fetch(stracer.fn, 0) + 1 if @debug
        @calls.push stracer unless stracer.args.nil?
      end
      @stream.close
    end

    def filter(filepath)
      return false if IGNORE_PATTERNS.any? { |regex| regex.match filepath }
      return true
    end

    def wrote_files
      @wrote_files ||= @calls.map { |call| call.args.writefile }.compact
    end

    def output_files
      @output_files ||= FileSet.new(wrote_files.select { |filepath| filter filepath }.map { |path| Pathname.new(@workdir).join(path) })
    end

    def read_files
      @read_files ||= @calls.map { |call| call.args.readfile }.compact
    end

    def input_files
      @input_files ||= read_files.select { |filepath| filter filepath }.map { |path| Pathname.new(@workdir).join(path) }
    end

    def log_stdout(logger)
      super
      if @debug and not skip?
        whitespace = ' ' * 7
        logger.debug { "#{whitespace}Strace saved output to: #{result_path}" }
        logger.debug { "#{whitespace}Strace read files (#{input_files.length}): #{input_files.map(&:to_s)}" }
        logger.debug { "#{whitespace}Strace wrote files (#{output_files.length}): #{output_files.map(&:to_s)}" }
        logger.debug { "#{whitespace}Strace syscall count: #{@stats}" }
      end
    end

    def to_s
      @orig_command
    end
  end
end
