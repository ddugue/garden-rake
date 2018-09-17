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
    @files << file
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
end

class FileGroup
  include Enumerable

  def initialize(*args)
  end


end
