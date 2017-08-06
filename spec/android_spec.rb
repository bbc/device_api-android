require 'spec_helper'
require 'device_api/android/device'

describe DeviceAPI::Android::Device do
  describe '.model' do
    it 'Returns model name' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')

      allow(Open3).to receive(:capture3) { ['[ro.product.model]: [HTC One]\n', '', STATUS_ZERO] }
      expect(device.model).to eq('HTC One')
    end
  end

  describe '.orientation' do
    it 'Returns portrait when device is portrait' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 0\r\n", '', STATUS_ZERO] }

      expect(device.orientation)
        .to eq(:portrait)
    end

    it 'Returns landscape when device is landscape' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 1\r\n", '', STATUS_ZERO] }

      expect(device.orientation)
        .to eq(:landscape)
    end

    it 'Returns landscape when device is landscape for a kindle Fire' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 3\r\n", '', STATUS_ZERO] }

      expect(device.orientation)
        .to eq(:landscape)
    end

    it 'Returns an error if response not understood' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')

      allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 564654654\n", '', STATUS_ZERO] }

      expect { device.orientation }
        .to raise_error(StandardError, 'Device orientation not returned got: 564654654.')
    end

    it 'Returns an error if no device found' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')

      allow(Open3).to receive(:capture3) { ["error: device not found\n", '', STATUS_ZERO] }

      expect { device.orientation }
        .to raise_error(StandardError, 'No output returned is there a device connected?')
    end

    it 'Can handle device orientation changes during a test' do
      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      landscape = "SurfaceOrientation: 1\r\n"
      portrait  = "SurfaceOrientation: 0\r\n"

      allow(Open3).to receive(:capture3) { [portrait, '', STATUS_ZERO] }
      expect(device.orientation)
        .to eq(:portrait)
      allow(Open3).to receive(:capture3) { [landscape, '', STATUS_ZERO] }
      expect(device.orientation)
        .to eq(:landscape)
    end

    it 'Can filter on large amounts of adb output to find the correct value', type: 'adb' do
      out = <<-EOF
        uchMajor: min=0, max=15, flat=0, fuzz=0, resolution=0
        TouchMinor: unknown range
        ToolMajor: unknown range
        ToolMinor: unknown range
        Orientation: unknown range
        Distance: unknown range
        TiltX: unknown range
        TiltY: unknown range
        TrackingId: min=0, max=65535, flat=0, fuzz=0, resolution=0
        Slot: min=0, max=9, flat=0, fuzz=0,
        resolution=0
        Calibration:
        touch.size.calibration: diameter
        touch.size.scale: 22.500
        touch.size.bias: 0.000
        touch.size.isSummed: false
        touch.pressure.calibration: amplitude
        touch.pressure.scale: 0.013
        touch.orientation.calibration: none
        touch.distance.calibration: none
        touch.coverage.calibration: none
        Viewport: displayId=0, orientation=0, logicalFrame=[0, 0, 768, 1280], physicalFrame=[0, 0, 768, 1280], deviceSize=[768, 1280]
        SurfaceWidth: 768px
        SurfaceHeight: 1280px
        SurfaceLeft: 0
        SurfaceTop: 0
        SurfaceOrientation: 0
        Translation and Scaling Factors:
        XTranslate: 0.000
        YTranslate: 0.000
        XScale: 0.500
        YScale: 0.500
        XPrecision: 2.000
        YPrecision: 2.000
      EOF

      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }

      expect(device.orientation)
        .to eq(:portrait)
    end
  end

  describe '.install' do
    it 'Can install an apk' do
      out = <<-EOF
        4458 KB/s (9967857 bytes in 2.183s)
        pkg: /data/local/tmp/bbciplayer-debug.apk
        Success
      EOF

      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect(device.install('some_apk.spk')).to eq(:success)
    end

    it 'Can display an error when the apk is not found' do
      out = "can't find 'fake.apk' to install"

      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect { device.install('fake.apk') }
        .to raise_error(StandardError, "can't find 'fake.apk' to install")
    end

    it 'Can display an error message when no apk is specified' do
      out = 'No apk specified.'

      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect { device.install('fake.apk') }
        .to raise_error(StandardError, 'No apk specified.')
    end

    it 'Can display an error when the apk is already installed' do
      out = 'Failure [INSTALL_FAILED_ALREADY_EXISTS]'

      device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
      allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
      expect { device.install('fake.apk') }
        .to raise_error(StandardError, 'Failure [INSTALL_FAILED_ALREADY_EXISTS]')
    end

    describe '.uninstall' do
      it 'Can uninstall an apk' do
        out = 'Success'

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.uninstall('pack_name'))
          .to eq(:success)
      end

      it 'Can raise an error if the uninstall was unsuccessful' do
        out = 'Failure'

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect { device.uninstall('pack_name') }
          .to raise_error(StandardError, "Unable to install 'package_name' Error Reported: Failure")
      end
    end

    describe '.package_name' do
      out = "package: name='bbc.iplayer.android' versionCode='4200066' versionName='4.2.0.66'"

      it 'Can get the package name from an apk' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.package_name('iplayer.apk'))
          .to eq('bbc.iplayer.android')
      end

      it 'Can get the version number from an apk' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.app_version_number('iplayer.apk')).to eq('4.2.0.66')
      end

      it 'can raise an error if the app package name is not found' do
        out = "package: versionCode='4200066' versionName='4.2.0.66'"

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect { device.package_name('iplayer.apk') }
          .to raise_error(StandardError, 'Package name not found')
      end

      it 'can raise an error if the app version number is not found' do
        out = "package: name='bbc.iplayer.android' yyyyy='xxxxxxxx' qqqqq='rrrrrrrr'"

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect { device.app_version_number('iplayer.apk') }
          .to raise_error(StandardError, 'Version number not found')
      end

      it 'can raise an error if aapt can not be found' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { ['', '', STATUS_ONE] }
        expect { device.app_version_number('iplayer.apk') }
          .to raise_error(StandardError, 'aapt not found - please create a symlink in $ANDROID_HOME/tools')
      end

      it 'can return the Wifi mac address' do
        out = <<-EOF
          4: ip6tnl0: <NOARP> mtu 1452 qdisc noop state DOWN
              link/tunnel6 :: brd ::
          5: p2p0: <NO-CARRIER,BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state DORMANT qlen 1000
              link/ether 42:b4:cd:73:8f:8b brd ff:ff:ff:ff:ff:ff
              inet6 fe80::40b4:cdff:fe73:8f8b/64 scope link
                 valid_lft forever preferred_lft forever
          6: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
              link/ether fc:c2:de:6a:04:9e brd ff:ff:ff:ff:ff:ff
              inet 192.168.101.227/24 brd 192.168.101.255 scope global wlan0
              inet6 fe80::42b4:cdff:fe73:8f8b/64 scope link
                 valid_lft forever preferred_lft forever
          EOF

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.wifi_mac_address).to eq('fc:c2:de:6a:04:9e')
      end

      it 'can return the Wifi mac address on an Android 6.0 and above device' do
        out = <<-EOF
          5: p2p0: <NO-CARRIER,BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state DORMANT qlen 1000
              link/ether 42:b4:cd:73:8f:8b brd ff:ff:ff:ff:ff:ff
              inet6 fe80::40b4:cdff:fe73:8f8b/64 scope link
                 valid_lft forever preferred_lft forever
          6: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
              link/ether 00:9A:CD:5E:CC:40 brd ff:ff:ff:ff:ff:ff
              inet 192.168.101.227/24 brd 192.168.101.255 scope global wlan0
              inet6 fe80::42b4:cdff:fe73:8f8b/64 scope link
                 valid_lft forever preferred_lft forever
        EOF

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.wifi_mac_address).to eq('00:9A:CD:5E:CC:40')
      end

      it 'will not crash if Wifi is not enabled' do
        out = <<-EOF
          lo         UP             127.0.0.1/8   0x00000049 00:00:00:00:00:00
          rmnet_usb0 DOWN             0.0.0.0/0   0x00001002 9a:ca:4c:c4:25:5b
        EOF

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect { device.wifi_mac_address }.to_not raise_error
      end

      it 'will return the IP address on a pre-6.0 android device' do
        out = <<-EOF
          wlan0: ip 10.10.1.108 mask 255.255.0.0 flags [up broadcast running multicast]
        EOF
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.ip_address).to eq('10.10.1.108')
      end

      it 'will return the IP address on a 6.0 and above device' do
        out = <<-EOF
          wlan0     Link encap:Ethernet  HWaddr 00:9A:CD:5E:CC:40
                    inet addr:10.10.1.108  Bcast:10.10.255.255  Mask:255.255.0.0
                    inet6 addr: ff80::29a:cbdf:ff5f:cc40/64 Scope: Link
                    UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
                    RX packets:3132210 errors:0 dropped:2310977 overruns:0 frame:0
                    TX packets:87349 errors:0 dropped:0 overruns:0 carrier:0
                    collisions:0 txqueuelen:1000
                    RX bytes:537224812 TX bytes:9711181
        EOF
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', STATUS_ZERO] }
        expect(device.ip_address).to eq('10.10.1.108')
      end
    end
  end
end
