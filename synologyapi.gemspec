Gem::Specification.new do |s|
  s.name = 'synologyapi'
  s.version = '0.0.1'
  s.date = '2010-01-02'
  s.authors = ['Stéphane de Wit']
  s.email = 'contact <AT> stephanedewit.be'
  s.summary = 'An API to manage Synology Disk Stations'
  s.homepage = 'http://www.stephanedewit.be'
  s.description = 'An API to manage Synology Disk Stations'
  s.files = ['MIT-LICENSE', 'lib/connection.rb', 'lib/downloadstation.rb', 'lib/errors.rb']
  s.add_dependency('json', '>= 1.1.9')
end
