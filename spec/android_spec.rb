require 'device_api/android/device'
include RSpec

describe DeviceAPI::Android::Device do

    describe '.model' do

      it 'Returns model name' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')

        allow(Open3).to receive(:capture3) { ['[ro.product.model]: [HTC One]\n', '', $STATUS_ZERO] }
        expect(device.model).to eq('HTC One')
      end

    end

    describe '.orientation' do
      it 'Returns portrait when device is portrait' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 0\r\n", '', $STATUS_ZERO] }

        expect(device.orientation).
            to eq(:portrait)
      end

      it 'Returns landscape when device is landscape' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 1\r\n", '', $STATUS_ZERO] }

        expect(device.orientation).
            to eq(:landscape)
      end

      it 'Returns landscape when device is landscape for a kindle Fire' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 3\r\n", '', $STATUS_ZERO] }

        expect(device.orientation).
            to eq(:landscape)
      end

      it 'Returns an error if response not understood' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')

        allow(Open3).to receive(:capture3) { ["SurfaceOrientation: 564654654\n", '', $STATUS_ZERO] }

        expect { device.orientation }.
          to raise_error(StandardError, 'Device orientation not returned got: 564654654.')
      end

      it 'Returns an error if no device found' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')

        allow(Open3).to receive(:capture3) { ["error: device not found\n", '', $STATUS_ZERO] }

        expect { device.orientation }.
            to raise_error(StandardError, 'No output returned is there a device connected?')
      end

      it 'Can handle device orientation changes during a test' do
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        landscape = "SurfaceOrientation: 1\r\n"
        portrait = "SurfaceOrientation: 0\r\n"

        allow(Open3).to receive(:capture3) { [portrait, '', $STATUS_ZERO] }
        expect(device.orientation).
            to eq(:portrait)
        allow(Open3).to receive(:capture3) { [landscape, '', $STATUS_ZERO] }
        expect(device.orientation).
            to eq(:landscape)
      end

      it 'Can filter on large amounts of adb output to find the correct value', type: 'adb' do
        out = <<_______________________________________________________
uchMajor: min=0, max=15, flat=0, fuzz=0, resolution=0\r\n        TouchMinor: unknown range\r\n
ToolMajor: unknown range\r\n        ToolMinor: unknown range\r\n        Orientation: unknown range\r\n
Distance: unknown range\r\n        TiltX: unknown range\r\n        TiltY: unknown range\r\n
TrackingId: min=0, max=65535, flat=0, fuzz=0, resolution=0\r\n        Slot: min=0, max=9, flat=0, fuzz=0,
resolution=0\r\n      Calibration:\r\n        touch.size.calibration: diameter\r\n
touch.size.scale: 22.500\r\n        touch.size.bias: 0.000\r\n        touch.size.isSummed: false\r\n
touch.pressure.calibration: amplitude\r\n        touch.pressure.scale: 0.013\r\n        touch.orientation.calibration: none\r\n
 touch.distance.calibration: none\r\n        touch.coverage.calibration: none\r\n      Viewport: displayId=0, orientation=0,
logicalFrame=[0, 0, 768, 1280], physicalFrame=[0, 0, 768, 1280], deviceSize=[768, 1280]\r\n      SurfaceWidth: 768px\r\n
 SurfaceHeight: 1280px\r\n      SurfaceLeft: 0\r\n      SurfaceTop: 0\r\n      SurfaceOrientation: 0\r\n
 Translation and Scaling Factors:\r\n        XTranslate: 0.000\r\n        YTranslate: 0.000\r\n        XScale: 0.500\r\n
     YScale: 0.500\r\n        XPrecision: 2.000\r\n        YPrecision: 2.000\r\n
_______________________________________________________
        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }

        expect(device.orientation).
            to eq(:portrait)

      end

    end

    describe '.install' do

      it 'Can install an apk' do
        out = <<_______________________________________________________
      4458 KB/s (9967857 bytes in 2.183s)
      pkg: /data/local/tmp/bbciplayer-debug.apk
      Success
_______________________________________________________

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
        expect(device.install('some_apk.spk')).
            to eq(:success)
      end

      it 'Can display an error when the apk is not found' do
        out = "can't find 'fake.apk' to install"

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
        expect { device.install('fake.apk') }.
            to raise_error(StandardError, "can't find 'fake.apk' to install")
      end

      it 'Can display an error message when no apk is specified' do
        out = 'No apk specified.'

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
        expect { device.install('fake.apk') }.
            to raise_error(StandardError, 'No apk specified.')
      end

      it 'Can display an error when the apk is already installed' do
        out = 'Failure [INSTALL_FAILED_ALREADY_EXISTS]'

        device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
        allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
        expect { device.install('fake.apk') }.
            to raise_error(StandardError, 'Failure [INSTALL_FAILED_ALREADY_EXISTS]')
      end

      describe '.uninstall' do

        it 'Can uninstall an apk' do
          out = 'Success'

          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect(device.uninstall('pack_name')).
              to eq(:success)
        end

        it 'Can raise an error if the uninstall was unsuccessful' do
          out = 'Failure'

          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect { device.uninstall('pack_name') }.
              to raise_error(StandardError, "Unable to install 'package_name' Error Reported: Failure")
        end

      end

      describe '.package_name' do
        out = "package: name='bbc.iplayer.android' versionCode='4200066' versionName='4.2.0.66'"

        it 'Can get the package name from an apk' do

          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect(device.package_name('iplayer.apk')).
            to eq('bbc.iplayer.android')
        end

        it 'Can get the version number from an apk' do
          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect(device.app_version_number('iplayer.apk')).
              to eq('4.2.0.66')
        end

        it 'can raise an error if the app package name is not found' do
          out = "package: versionCode='4200066' versionName='4.2.0.66'"

          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect { device.package_name('iplayer.apk') }.
              to raise_error(StandardError, 'Package name not found')
        end

        it 'can raise an error if the app version number is not found' do
          out = "package: name='bbc.iplayer.android' yyyyy='xxxxxxxx' qqqqq='rrrrrrrr'"

          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect { device.app_version_number('iplayer.apk') }.
              to raise_error(StandardError, 'Version number not found')
        end

        it 'can raise an error if aapt can not be found' do
          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { ['', '', $STATUS_ONE] }
          expect { device.app_version_number('iplayer.apk') }.
              to raise_error(StandardError, 'aapt not found - please create a symlink in $ANDROID_HOME/tools')
        end

        it 'can return the Wifi mac address' do
          out = <<EOF
lo       UP                                   127.0.0.1/8   0x00000049 00:00:00:00:00:00
rmnet_usb0 DOWN                                   0.0.0.0/0   0x00001002 9a:ca:4c:c4:25:5b
wlan0    UP                                     0.0.0.0/0   0x00001003 fc:c2:de:6a:04:9e
EOF
          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect(device.wifi_mac_address).to eq('fc:c2:de:6a:04:9e')
        end

        it 'can return the Wifi IP address' do
          out = <<EOF
lo       UP                                   127.0.0.1/8   0x00000049 00:00:00:00:00:00
rmnet_usb0 DOWN                                   0.0.0.0/0   0x00001002 9a:ca:4c:c4:25:5b
wlan0    UP                                     192.168.1.1/0   0x00001003 fc:c2:de:6a:04:9e
EOF
          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect(device.ip_address).to eq('192.168.1.1')
        end

        it 'will not crash if Wifi is not enabled' do
          out = <<EOF
lo       UP                                   127.0.0.1/8   0x00000049 00:00:00:00:00:00
rmnet_usb0 DOWN                                   0.0.0.0/0   0x00001002 9a:ca:4c:c4:25:5b
EOF

          device = DeviceAPI::Android::Device.new(serial: 'SH34RW905290')
          allow(Open3).to receive(:capture3) { [out, '', $STATUS_ZERO] }
          expect { device.wifi_mac_address }.to_not raise_error
        end
      end
    end
  end
