require 'simplecov'
SimpleCov.start

if ENV['CI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift('./lib/')

ProcessStatusStub = Struct.new(:exitstatus)
STATUS_ZERO = ProcessStatusStub.new(0)
STATUS_ONE = ProcessStatusStub.new(1)

ENV['PATH'] = "./spec/adb_mock/:" + ENV['PATH']
