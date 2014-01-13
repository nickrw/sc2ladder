Gem::Specification.new do |s|
  s.name = 'sc2ladder'
  s.version = '1.0'
  s.summary = 'Sinatra application to manage and run an Elo-based Starcraft 2 ladder'
  s.authors = ['Nicholas Robinson-Wall']
  s.email = ['nick@robinson-wall.com']
  s.required_ruby_version = '>= 1.9.2'
  s.executables = ["sc2ladder"]
  s.files = Dir['{lib,bin,views,public}/**/*'] + ['config.ru']
  s.add_dependency 'sinatra'
  s.add_dependency 'json'
  s.add_dependency 'ggtracker'
  s.add_dependency 'actionpack'
  s.add_development_dependency 'rspec'
end
