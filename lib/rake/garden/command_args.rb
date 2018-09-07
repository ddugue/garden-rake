##
# Small data structure to pass Arguments to an SH Command
class Args
  attr_reader :args

  def initialize(*args, **kwargs)
    if args[0].is_a? Args
      @args = args[0].args
    else
      @args = []
    end

    args.each do |arg|
      push arg if (arg.is_a? String) || (arg.is_a? Array)
    end

    @kwargs = kwargs
  end

  def push(arg)
    arg.format_with_file! if arg.is_a? String
    arg.map!(&:format_with_file!) if arg.is_a? Array
    @args.push(arg)
  end

  def length
    @args.length
  end


  def >>(other)
    push other
    self
  end
end

##
# Args used for sh calls (cp, sh, mv, etc...)
class ShArgs < Args
  ##
  # Return a fileset of files a
  def input
    return nil unless length >= 2
    return FileSet.new(@args[0])
  end

  def output
    return nil unless length >= 3
    return FileSet.new(@args[-1])
  end

  def command
    case length
    when 1 then @args[0]
    when 2 then @args[1]
    when 3 then @args[1]
    end
  end
end

##
# Args used for
class ChainArgs < Args
end
