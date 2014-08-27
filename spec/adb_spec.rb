$LOAD_PATH.unshift('./lib/')

require 'device_api'
require 'device_api/android/adb'

include RSpec

ProcessStatusStub = Struct.new(:exitstatus)
$STATUS_ZERO = ProcessStatusStub.new(0)

describe DeviceAPI::Android::ADB do
  describe '.execute' do

    before(:all) do
      @result = DeviceAPI::Android::ADB.execute('echo boo')
    end

    it 'returns an OpenStruct execution result' do
      expect(@result).to be_a OpenStruct
    end

    it 'captures exit value in hash' do
      expect(@result.exit).to eq(0)
    end

    it 'captures stdout in hash' do
      expect(@result.stdout).to eq("boo\n")
    end

    it 'capture stderr in hash' do
      expect(@result.stderr).to eq('')
    end

  end

#
#
# FIRST
  describe '.devices' do

    it 'returns an empty array when there are no devices' do
      out = <<eos
List of devices attached


eos
      allow(Open3).to receive(:capture3) {
        [out, '', $STATUS_ZERO]
      }
      expect(DeviceAPI::Android::ADB.devices).to eq([])
    end

    it "returns an array with a single item when there's one device attached" do
      out = <<_______________________________________________________
List of devices attached
SH34RW905290	device

_______________________________________________________
      allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to eq([{ 'SH34RW905290' => 'device' }])
    end

    it 'returns an an array with multiple items when there are multiple items attached' do
      out = <<_______________________________________________________
List of devices attached
SH34RW905290	device
123456324	no device

_______________________________________________________
      allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to eq([{ 'SH34RW905290' => 'device' }, { '123456324' => 'no device' }])
    end
    
    it 'can deal with extra output when adb starts up' do
      out = <<_______________________________________________________
* daemon not running. starting it now on port 5037 *
* daemon started successfully *
List of devices attached
SH34RW905290	device
_______________________________________________________
      allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to eq([{ 'SH34RW905290' => 'device' }])
    end

    it 'can deal with no devices connected' do
      allow(Open3).to receive(:capture3) { ["error: device not found\n", '', $STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to be_empty
    end
  end

  describe ".get_uptime" do
    it "can process an uptime" do
      out = <<_______________________________________________________
12307.23 48052.0
_______________________________________________________
      allow(Open3).to receive(:capture3) { [ out, '', $STATUS_ZERO] }
      expect( DeviceAPI::Android::ADB.get_uptime('SH34RW905290')).to eq( 12307 )
    end
  end
  
  describe ".getprop" do
    
    it "Returns a hash of name value pair properties" do
      out = <<________________________________________________________
[net.hostname]: [android-f1e4efe3286b0785]
[dhcp.wlan0.ipaddress]: [10.0.1.34]
[ro.build.version.release]: [4.1.2]
[ro.build.version.sdk]: [16]
[ro.product.bluetooth]: [4.0]
[ro.product.device]: [m7]
[ro.product.display_resolution]: [4.7 inch 1080p resolution]
[ro.product.manufacturer]: [HTC]
[ro.product.model]: [HTC One]
[ro.product.name]: [m7]
[ro.product.processor]: [Quadcore]
[ro.product.ram]: [2GB]
[ro.product.version]: [1.28.161.7]
[ro.product.wifi]: [802.11 a/b/g/n/ac]
[ro.revision]: [3]
[ro.serialno]: [SH34RW905290]
[ro.sf.lcd_density]: [480]
________________________________________________________

      allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }

      props = DeviceAPI::Android::ADB.getprop('SH34RW905290')

      expect(props).to be_a Hash
      expect(props['ro.product.model']).to eq('HTC One')
    end
  end
  
  describe ".get_status" do
    
    it "Returns a state for a single device" do
      out = <<_______________________________________________________
device
_______________________________________________________
      allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
    
      state = DeviceAPI::Android::ADB.get_state('SH34RW905290')
    
      expect(state).to eq 'device'
    end
  end
  
  describe ".monkey" do
    
    it "Constructs and executes monkey command line" do
      out = <<_______________________________________________________
** Monkey aborted due to error.
Events injected: 3082
:Sending rotation degree=0, persist=false
:Dropped: keys=88 pointers=180 trackballs=0 flips=0 rotations=0
## Network stats: elapsed time=14799ms (0ms mobile, 0ms wifi, 14799ms not connected)
** System appears to have crashed at event 3082 of 5000000 using seed 1409644708681
  end
_______________________________________________________
      allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
 
      expect( DeviceAPI::Android::ADB.monkey( '1234323', :events => 5000, :package => 'my.app.package' )).to be_a OpenStruct
    end
  end

    describe '.execute_with_timeout_and_retry' do
      it 'If the command takes too long then the command should retry then fail' do
        stub_const('DeviceAPI::Android::ADB::ADB_COMMAND_TIMEOUT',1)
        stub_const('DeviceAPI::Android::ADB::ADB_COMMAND_RETRIES',5)
        sleep_time = 5
        cmd = "sleep #{sleep_time.to_s}"
        expect { DeviceAPI::Android::ADB.execute_with_timeout_and_retry(cmd) }.to raise_error(DeviceAPI::Android::ADBCommandTimeoutError)
      end

      it 'If the command takes less time than the timeout to execute then the command should pass' do
        stub_const('DeviceAPI::Android::ADB::ADB_COMMAND_TIMEOUT',2)
        stub_const('DeviceAPI::Android::ADB::ADB_COMMAND_RETRIES',5)
        sleep_time = 1
        cmd = "sleep #{sleep_time.to_s}"
        DeviceAPI::Android::ADB.execute_with_timeout_and_retry(cmd)
      end

    end

end
