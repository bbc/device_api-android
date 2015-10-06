Gem::Specification.new do |s|
  s.name        = 'device_api-android'
  s.version     = '1.1.2'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Android Device Management API'
  s.description = 'Android implementation of DeviceAPI'
  s.authors     = ['David Buckhurst','Jitesh Gosai', 'Jon Wilson']
  s.email       = 'david.buckhurst@bbc.co.uk'
  s.files       = `git ls-files`.split "\n"
  s.homepage    = 'https://github.com/bbc/device_api-android'
  s.license     = 'MIT'
  s.add_runtime_dependency 'device_api', '>=1.0', '<2.0'
  s.add_development_dependency 'rspec'
end
