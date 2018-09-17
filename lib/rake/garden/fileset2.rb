require 'rake/garden/filepath'

class Fileset
  include Enumerable

  def initialize(*args)
    @files = []
    @pending = true
    @folder_root = nil
  end

  def resolve
    @pending = false
  end

  def <<(file)
    if file.is_a? Array
      @files = file
    else
      @files << file
    end
  end

  def each
    return enum_for(:each) unless block_given?

    resolve if @pending

    previous_root = FileAwareString.folder_root
    previous_file = FileAwareString.file

    FileAwareString.folder_root = @folder_root
    @files.each do |file|
      FileAwareString.file = file
      yield file
    end

    FileAwareString.folder_root = previous_root
    FileAwareString.file = previous_file
  end
end

class GlobFileset < Fileset
  GLOB = Regexp.new(/^[^\*]*/)

  def initialize(glob)
    super
    @glob = glob
    @folder_root ||= (GLOB.match(glob)[0] || '').to_s
  end

  def resolve
    super
    @files = (Dir.glob @glob).sort
  end

  def self.is_glob(path)
    path.include? "*"
  end
end

class FilesetGroup
  include Enumerable

  def append_fileset(fileset)
    if fileset.is_a? Fileset
      @filesets.unshift fileset
    elsif fileset.is_a? String

      if GlobFileset.is_glob(fileset)
        @filesets.unshift GlobFileset.new(fileset)
      else
        @orphans.unshift(fileset)
      end
    else
      fileset.each { |fs| append_fileset(fs) }
    end
  end

  def initialize(*args)
    @filesets = []
    @orphans = []

    append_fileset(args)

    unless @orphans.empty?
      fs = Fileset.new
      fs << @orphans
      @filesets.unshift(fs)
    end
  end

  def each
    return enum_for(:each) unless block_given?
    puts "#{@filesets}"
    @filesets.each do |fs|
      fs.each do |file|
        puts "#{file}"
        yield file
      end
    end
  end
end
