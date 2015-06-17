# Encoding: utf-8
require 'device_api/device'
require 'device_api/android/adb'
require 'device_api/android/aapt'

# DeviceAPI - an interface to allow for automation of devices
module DeviceAPI
  # Android component of DeviceAPI
  module Android
    # Device class used for containing the accessors of the physical device information
    class Device < DeviceAPI::Device
      def initialize(options = {})
        @serial = options[:serial]
        @state = options[:state]
      end

      # Mapping of device status - used to provide a consistent status across platforms
      # @return (String) common status string
      def status
        {
            'device' => :ok,
            'no device' => :dead,
            'offline' => :offline
        }[@state]
      end

      # Return the device range
      # @return (String) device range string
      def range
        device = self.device
        model  = self.model

        return device if device == model
        "#{device}_#{model}"
      end

      # Return the device type
      # @return (String) device type string
      def device
        get_prop('ro.product.device')
      end

      # Return the device model
      # @return (String) device model string
      def model
        get_prop('ro.product.model')
      end

      # Return the device manufacturer
      # @return (String) device manufacturer string
      def manufacturer
        get_prop('ro.product.manufacturer')
      end

      # Return the Android OS version
      # @return (String) device Android version
      def version
        get_prop('ro.build.version.release')
      end

      # Return the device orientation
      # @return (String) current device orientation
      def orientation
        res = get_dumpsys('SurfaceOrientation')

        case res
          when '0','2'
            :portrait
          when '1', '3'
            :landscape
          when nil
            fail StandardError, 'No output returned is there a device connected?', caller
          else
            fail StandardError, "Device orientation not returned got: #{res}.", caller
        end
      end

      # Install a specified apk
      # @param [String] apk string containing path to the apk to install
      # @return [Symbol, Exception] :success when the apk installed successfully, otherwise an error is raised
      def install(apk)
        fail StandardError, 'No apk specified.', caller if apk.empty?
        res = install_apk(apk)

        case res
          when 'Success'
            :success
          else
            fail StandardError, res, caller
        end
      end

      # Uninstall a specified package
      # @param [String] package_name name of the package to uninstall
      # @return [Symbol, Exception] :success when the package is removed, otherwise an error is raised
      def uninstall(package_name)
        res = uninstall_apk(package_name)
        case res
          when 'Success'
            :success
          else
            fail StandardError, "Unable to install 'package_name' Error Reported: #{res}", caller
        end
      end

      # Return the package name for a specified apk
      # @param [String] apk string containing path to the apk
      # @return [String, Exception] package name if it can be found, otherwise an error is raised
      def package_name(apk)
        @apk = apk
        result = get_app_props('package')['name']
        fail StandardError, 'Package name not found', caller if result.nil?
        result
      end

      # Return the app version number for a specified apk
      # @param [String] apk string containing path to the apk
      # @return [String, Exception] app version number if it can be found, otherwise an error is raised
      def app_version_number(apk)
        @apk = apk
        result = get_app_props('package')['versionName']
        fail StandardError, 'Version number not found', caller if result.nil?
        result
      end

      # Initiate monkey tests
      # @param [Hash] args arguments to pass on to ADB.monkey
      def monkey(args)
        ADB.monkey(serial, args)
      end

      # Capture screenshot on device
      # @param [Hash] args arguments to pass on to ADB.screencap
      def screenshot(args)
        ADB.screencap(serial, args)
      end

      # Get the IMEI number of the device
      # @return (String) IMEI number of current device
      def imei
        get_phoneinfo['Device ID']
      end

      private

      def get_app_props(key)
        unless @app_props
          @app_props = AAPT.get_app_props(@apk)
        end
        @app_props.each { |x| break x[key] }
      end

      def get_prop(key)
        if !@props || !@props[key]
          @props = ADB.getprop(serial)
        end
        @props[key]
      end

      def get_dumpsys(key)
        @props = ADB.getdumpsys(serial)
        @props[key]
      end

      def get_phoneinfo
        ADB.getphoneinfo(serial)
      end

      def install_apk(apk)
        ADB.install_apk(apk: apk, serial: serial)
      end

      def uninstall_apk(package_name)
        ADB.uninstall_apk(package_name: package_name, serial: serial)
      end

      def get_wifi_status
        ADB.wifi(serial)
      end
    end
  end
end
