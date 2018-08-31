require 'open3'
require 'colorize'

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
end

class ArgParser
  DELIMITERS = ['[', '(', '{', '"', "'"]

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
end

class StraceParser
  def initialize(stream)
    @stream = stream
  end

  def each(&block)
    @stream.each do |line|
      chars = line.each_char.to_a
      index = 0
      c = chars[0]
      next if c == '+' || c == '-'

      until c == "("
        c = chars[index]
        index += 1
      end

      fn = chars[0, index-1 ].join
      if fn == 'open'
        args = ArgParser.new(chars, index - 1)
        a = args.parse
        rest = chars[args.index+1..-1].join
        yield fn, a, rest
      end
    end
  end
end
# module Rake::Garden
#   class StraceParser
#     def initialize(stream)
#     end

#     def parse_linux(line)
#       return if line.start_with? '-' or line.start_with '+'
#       line_char = line

#       [
#         fn_stack.reverse.join,
#         arg_stack.map(&:reverse).map(&:join),
#         result_stack.reverse.join,
#       ]
#     end
#     def each(&block)
#       stream.each do |line|

#       yield
#     end
#   end
#   class Stracer
#     def initialize(command)
#       @command = command
#     end

#     def file_hash
#       return "/tmp/#{@command.hash}"
#     end

#     def command()
#       return "strace -e file -o #{file_hash} #{@command}"
#     end

#     def parse(output)

#       output.each do |line|
#         matches = /opena?t?\(([^,\)]*),\s*([^,\)]*)(?:,\s*([^,\)]*))?\)/.match line
#         if matches
#           is_relative = matches[1] == 'AT_FDCWD'
#           path = matches[-1] ? matches[-2] : matches[-3]
#           path.gsub!('"', '')
#           flags = matches[-1] ? matches[-1] : matches[-2]
#           flags = flags.split('|')
#           puts "#{is_relative} #{path} @ '#{flags}'"
#         end
#       end
#     end

#     def run()
#       Open3.popen3(command) {|stdin, stdout, stderr, wait_thr|
#         exit_status = wait_thr.value # Process::Status object returned.
#         if exit_status != 0
#           $stderr.puts "There was a problem running command: '#{@command}'".red
#           $stderr.puts "############ COMMAND OUTPUT ###############".red
#           stderr.each do |line|
#             $stderr.puts line.red
#           end
#           exit(1)
#         end

#         parse(File.open file_hash, "r")
#       }
#     end
#   end
# end
