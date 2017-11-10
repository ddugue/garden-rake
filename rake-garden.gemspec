Gem::Specification.new do |s|
  s.name        = 'rake-garden'
  s.version     = '0.0.1'
  s.date        = '2017-11-10'
  s.summary     = 'Task extension for conditional execution'
  s.description = 'Automatically checks for task execution requirements via'\
                  ' inotify to make sure task executions only happen when'\
                  ' necessary'
  s.authors     = ['David Dugue']
  s.email       = 'ddugue@kumoweb.ca'
  s.files       = ["libs/rake-garden.rb"]
  s.homepage    = 'http://rubygems.org/gems/rake-garden'
  s.license     = 'MIT'
end
