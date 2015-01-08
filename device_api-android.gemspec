Gem::Specification.new do |s|
  s.name        = 'device_api-android'
  s.version     = '1.0.1'
  s.date        = '2014-09-01'
  s.summary     = 'Physical Device Management API'
  s.description = 'A common interface for physical devices'
  s.authors     = ['David Buckhurst','Jitesh Gosai']
  s.email       = 'david.buckhurst@bbc.co.uk'
  s.files       = `git ls-files`.split "\n"
  s.homepage    = 'https://github.com/bbc-test/device_api-android'
  s.license     = 'MIT'
  s.add_runtime_dependency 'device_api', '>=1.0'
  s.add_development_dependency 'rspec'
end
