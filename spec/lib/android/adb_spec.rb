require 'spec_helper'
require 'device_api'
require 'device_api/android/adb'

#
#
# FIRST
describe DeviceAPI::Android::ADB do
  describe '.devices' do
    it 'returns an empty array when there are no devices' do
      out = <<-EOF
        List of devices attached


      EOF

      allow(Open3).to receive(:capture3) {
        [out, '', STATUS_ZERO]
      }
      expect(DeviceAPI::Android::ADB.devices).to eq([])
    end

    it "returns an array with a single item when there's one device attached" do
      out = <<-EOF
        List of devices attached
        SH34RW905290	device

      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to eq([{ 'SH34RW905290' => 'device' }])
    end

    it 'returns an an array with multiple items when there are multiple items attached' do
      out = <<-EOF
        List of devices attached
        SH34RW905290	device
        123456324	no device

      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to eq([{ 'SH34RW905290' => 'device' }, { '123456324' => 'no device' }])
    end

    it 'can deal with extra output when adb starts up' do
      out = <<-EOF
        * daemon not running. starting it now on port 5037 *
        * daemon started successfully *
        List of devices attached
        SH34RW905290	device
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to eq([{ 'SH34RW905290' => 'device' }])
    end

    it 'can deal with no devices connected' do
      allow(Open3).to receive(:capture3) { ["error: device not found\n", '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.devices).to be_empty
    end
  end

  describe '.get_uptime' do
    it 'can process an uptime' do
      out = <<-EOF
        12307.23 48052.0
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.get_uptime('SH34RW905290')).to eq(12_307)
    end

    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.get_uptime('SH34RW905290') }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.get_uptime('SH34RW905290') }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end

  describe '.getprop' do
    it 'Returns a hash of name value pair properties' do
      out = <<-EOF
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
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }

      props = DeviceAPI::Android::ADB.getprop('SH34RW905290')

      expect(props).to be_a Hash
      expect(props['ro.product.model']).to eq('HTC One')
    end

    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.getprop('SH34RW905290') }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.getprop('SH34RW905290') }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end

  describe '.connect' do
    it "raises a ADBCommandError when it can't connect to IP address/port combination" do
      err = <<~EOF
        unable to connect to 192.168.0.1:5555
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.connect to raise_error(DeviceAPI::ADBCommandError) }
    end

    it 'raises a DeviceAlreadyConnectedError when the device is already connected' do
      err = <<~EOF
        already connected to 192.168.0.251:5555
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.connect to raise_error(DeviceAPI::DeviceAlreadyConnectedError) }
    end
  end

  describe '.disconnect' do
    it "raises a ADBCommandError when it can't connect to IP address/port combination" do
      err = <<~EOF
        No such device 192.167.0.1:5555
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.connect to raise_error(DeviceAPI::ADBCommandError) }
    end
  end

  describe '.get_state' do
    it 'Returns a state for a single device' do
      out = <<-EOF
        device
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }

      state = DeviceAPI::Android::ADB.get_state('SH34RW905290')

      expect(state).to eq 'device'
    end
  end

  describe '.monkey' do
    it 'Constructs and executes monkey command line' do
      out = <<-EOF
        ** Monkey aborted due to error.
        Events injected: 3082
        :Sending rotation degree=0, persist=false
        :Dropped: keys=88 pointers=180 trackballs=0 flips=0 rotations=0
        ## Network stats: elapsed time=14799ms (0ms mobile, 0ms wifi, 14799ms not connected)
        ** System appears to have crashed at event 3082 of 5000000 using seed 1409644708681
        end
      EOF
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }

      expect(DeviceAPI::Android::ADB.monkey('1234323', events: 5000, package: 'my.app.package')).to be_a OpenStruct
    end

    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.monkey('SH34RW905290', package: 'my.lovely.app') }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.monkey('SH34RW905290', package: 'my.lovely.app') }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end

  describe '.wifi' do
    it 'returns wifi info' do
      out = <<-EOF
        mNetworkInfo [type: WIFI[], state: CONNECTED/CONNECTED, reason: (unspecified), extra: "TVMP-DevNet", roaming: false, failover: false, isAvailable: true, isConnectedToProvisioningNetwork: false]
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.wifi('12345').class).to eq(Hash)
    end

    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.wifi('SH34RW905290') }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.wifi('SH34RW905290') }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end

  describe '.am' do
    it 'returns the stdout' do
      out = <<-EOF
        Starting: Intent { act=android.intent.action.MAIN cmp=com.android.settings/.wifi.WifiSettings }
      EOF

      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(DeviceAPI::Android::ADB.am('03157df373208426', '12345').class).to eq(String)
    end
  end

  describe '#get_network_info' do
    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.get_network_info('SH34RW905290') }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.get_network_info('SH34RW905290') }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end

  describe '#dumpsys' do
    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.dumpsys('SH34RW905290', 'dreams') }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.dumpsys('SH34RW905290', 'dreams') }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end

  describe '#screencap' do
    file_image = '/tmp/filename.png'

    it 'raises an UnauthorizedDevice exception' do
      err = <<~EOF
        error: device unauthorized. Please check the confirmation dialog on your device.
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.screencap('SH34RW905290', filename: file_image) }.to raise_error(DeviceAPI::UnauthorizedDevice)
    end

    it 'raises a DeviceNotFound exception' do
      err = <<~EOF
        error: device not found
      EOF

      allow(Open3).to receive(:capture3) { ['', err, STATUS_ONE] }
      expect { DeviceAPI::Android::ADB.screencap('SH34RW905290', filename: file_image) }.to raise_error(DeviceAPI::DeviceNotFound)
    end
  end
end
