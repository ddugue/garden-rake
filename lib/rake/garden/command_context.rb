require 'pathname'

require 'rake/garden/commands/echo'
require 'rake/garden/commands/set'
require 'rake/garden/commands/unset'
require 'rake/garden/commands/cd'
require 'rake/garden/commands/cp'
require 'rake/garden/commands/sh'

##
# Represent a context that enables to create a custom dsl to queue
# commands
module CommandsContext

  attr_accessor :workdir # Actual work directory of the chore
  attr_accessor :env     # Environment variable passed to commands

  def initialize(*args)
    @queue = []
    @workdir = Pathname.new(Pathname.pwd)
    @env = {}
    @command_index = 0 # Reference for command execution, see queue
    super
  end

  ##
  # Queue command for execution
  def queue(command)
    command.workdir = @workdir
    command.env = @env.clone

    @logger.debug("Queuing '#{command.to_s}'") if @logger

    @queue << command
    command
  end

  ##
  # Echo a simple message in the async context
  def echo *args
    queue EchoCommand.new(*args)
  end
  ##
  # Set variable environment
  # Can be used like set :VAR => value or set :VAR, value or set VAR:value
  def set(*args)
    queue SetCommand.new(self, *args)
  end

  ##
  # Unset an environment variable
  def unset(var)
    queue UnsetCommand.new(self, var)
  end

  ##
  # Change directory
  def cd(dir)
    queue ChangedirectoryCommand.new(self, dir)
  end

  ##
  # Copy file -> location
  def cp(f, name)
    queue CopyCommand.new(f, name)
  end


  ##
  # Run a shell command
  def sh(cmd)
    queue ShCommand.new(cmd)
  end

end
