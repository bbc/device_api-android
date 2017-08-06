require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift('./lib/')

ProcessStatusStub = Struct.new(:exitstatus)
STATUS_ZERO       = ProcessStatusStub.new(0)
STATUS_ONE        = ProcessStatusStub.new(1)

ENV['PATH'] = './spec/adb_mock/:' + ENV['PATH']
