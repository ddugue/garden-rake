require 'time'

##
# We extend the File module to add some useful methods
class File
  class << self
    def safe_mtime(file)
      exist?(file) ? mtime(file) : Time.at(0)
    end
  end
end
