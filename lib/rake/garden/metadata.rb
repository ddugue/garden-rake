require 'json'
require 'msgpack'
## TODO: Add some methods to access common value to delegate from execute module
module Rake::Garden

  class Metadata
    def initialize(filename=".garden")
      @filename = filename
    end

    # Return the hash representing the metadata
    # Metadata is a direct representation of its underlying data
    def data
      @data ||= open || Hash.new
      @data
    end
    def [](ind); data[ind]; end
    def []=(ind, value); data[ind] = value; end
    def key?(key); data.key? key; end
    def fetch(value, default); data.fetch(value, default); end

    def read()
      File.file?(@filename) ? File.read(@filename) : nil
    end

    ##
    # Return an hash based on the file
    ##
    def parse(file)
      raise "NotImplementedError"
    end

    ##
    # Save data to file
    ##
    def save()
      raise "NotImplementedError"
    end

    # Open the file to be parsed
    def open()
      logger = Logger.new
      file = read()
      return nil if file.nil?
      return parse(file)
    ensure
      if (logger != nil)
        logger.log "Load metadata #{@filename}"
      end
    end

    # Save the Metadata information to the filename
    def close()
      logger = Logger.new
      d = data
      File.open @filename, "w+" do |file|
        save(d, file)
      end
      logger.log "Saved metadata #{@filename}"
    end
  end

  ##
  # Class responsible to load data from JSON
  ##
  class JSONMetadata < Metadata
    def parse(file)
      JSON.load file
    end

    def save(data, file)
      JSON.dump(data, file)
    end
  end

  ##
  # Class responsible to load data from MsgPack
  ##
  class MSGPackMetadata < Metadata
    def parse(file)
      MessagePack.unpack file
    end

    def save(data, file)
      MessagePack.dump data, file
    end
  end
end
