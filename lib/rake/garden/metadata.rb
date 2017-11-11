
module Rake::Garden
  DEBUG = ENV.fetch("DEBUG", "true") == "true"
  if DEBUG
    require 'json'
  else
    require 'msgpack'
  end
  class Metadata
    include Singleton
    # Returns wether we use a JSON file (debug mode) or a msgpack file
    def json?; DEBUG; end

    def filename()
      @filename ||= ENV.fetch("GARDEN_FILE", json? ? ".garden.json" : ".garden")
    end

    # Return the hash representing the metadata
    # Metadata is a direct representation of its underlying data
    def data; @data ||= load; end
    def [](ind); data[ind]; end
    def []=(ind, value); data[ind] = value; end
    def key?(key); data.key? key; end
    def fetch(value, default); data.fetch value, default; end

    # Load the Message pack (or JSON file) and returns metadata
    def load()
      logger = Logger.new
      file = File.file?(filename) ? File.read(filename) : nil
      return Hash.new if file.nil?
      return JSON.load file if json?
      return MessagePack.unpack file
    ensure
      if (logger != nil)
        logger.log "Load metadata #{filename}"
      end
    end

    # Save the Metadata information to the filename
    def save()
      logger = Logger.new
      File.open filename, "w+" do |file|
        json? ? JSON.dump(data, file) : MessagePack.dump(data, file)
        logger.log "Saved metadata #{filename}"
      end
    end
  end
end
