
$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"

require 'rake'
require 'rake/garden/command_chore'
require 'rake/garden/metadata'
require 'rake/garden/options'

module Garden

  def options()
    $options ||= Option.new
  end

  def metadata()
    $metadata ||= JSONMetadata.new ".garden.json"
  end

  def chore(*args, &block) # :doc:
    CommandChore.define_task(options.parse, *args, &block)
  end

  at_exit {
    $metadata.save if $metadata
  }
end
