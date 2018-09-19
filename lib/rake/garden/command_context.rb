require 'pathname'

require 'rake/garden/command_args'

require 'rake/garden/commands/echo'
require 'rake/garden/commands/set'
require 'rake/garden/commands/unset'
require 'rake/garden/commands/cd'
require 'rake/garden/commands/cp'
require 'rake/garden/commands/sh'
require 'rake/garden/commands/mkdir'
require 'rake/garden/commands/daemon'

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

    @logger.debug(" Queuing '#{command}'") if @logger

    @queue << command
    command
  end

  ##
  # Create synchronously a folder
  def mkdir(folder)
    queue MakeDirCommand.new(self, folder)
  end

  ##
  # Echo a simple message in the async context
  def echo(*args)
    queue EchoCommand.new(self, *args)
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
  def cp(file, name)
    queue CopyCommand.new(self, file, name)
  end

  ##
  # Run a shell command
  def sh(*args)
    queue ShCommand.new(self, ShArgs.new(*args))
  end

  def strace(*args)
    queue StraceCommand.new(self, ShArgs.new(*args))
  end

  def daemon(cmd)
    queue DaemonCommand.new(self, cmd)
  end
end
