$LOAD_PATH.unshift('./lib/')

ProcessStatusStub = Struct.new(:exitstatus)
STATUS_OK = ProcessStatusStub.new(0)
STATUS_ERROR = ProcessStatusStub.new(1)

ENV['PATH'] = "./spec/adb_mock/:" + ENV['PATH']
