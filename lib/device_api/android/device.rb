# Encoding: utf-8
require 'device_api/device'
require 'device_api/android/adb'
require 'device_api/android/aapt'

module DeviceAPI
  module Android
    class Device < DeviceAPI::Device
      def initialize(options = {})
        @serial = options[:serial]
        @state = options[:state]
      end

      def status
        {
            'device' => :ok,
            'no device' => :dead,
            'offline' => :offline
        }[@state]
      end

      def model
        get_prop('ro.product.model')
      end

      def orientation
        res = get_dumpsys('SurfaceOrientation')

        case res
          when '0'
            :portrait
          when '1', '3'
            :landscape
          when nil
            fail StandardError, 'No output returned is there a device connected?', caller
          else
            fail StandardError, "Device orientation not returned got: #{res}.", caller
        end
      end

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

      def uninstall(package_name)
        res = uninstall_apk(package_name)
        case res
          when 'Success'
            :success
          else
            fail StandardError, "Unable to install 'package_name' Error Reported: #{res}", caller
        end
      end

      def package_name(apk)
        @apk = apk
        result = get_app_props('package')['name']
        fail StandardError, 'Package name not found', caller if result.nil?
        result
      end

      def app_version_number(apk)
        @apk = apk
        result = get_app_props('package')['versionName']
        fail StandardError, 'Version number not found', caller if result.nil?
        result
      end

      def monkey(args)
        ADB.monkey(serial, args)
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

      def install_apk(apk)
        ADB.install_apk(apk: apk, serial: serial)
      end

      def uninstall_apk(package_name)
        ADB.uninstall_apk(package_name: package_name, serial: serial)
      end
    end
  end
end
