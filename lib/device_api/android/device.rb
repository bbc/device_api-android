# Encoding: utf-8

require 'device_api/device'
require 'device_api/android/adb'
require 'device_api/android/aapt'
require 'android/devices'

# DeviceAPI - an interface to allow for automation of devices
module DeviceAPI
  # Android component of DeviceAPI
  module Android
    # Device class used for containing the accessors of the physical device information
    class Device < DeviceAPI::Device
      attr_reader :qualifier

      @@subclasses = {}

      # Called by any inheritors to register themselves with the parent class
      def self.inherited(klass)
        key = /::([^:]+)$/.match(klass.to_s.downcase)[1].to_sym
        @@subclasses[key] = klass
      end

      # Returns an object of the specified type, if it exists. Defaults to returning self
      def self.create(type, options = {})
        return @@subclasses[type.to_sym].new(options) if @@subclasses[type.to_sym]
        new(options)
      end

      def initialize(options = {})
        # For devices connected with USB, qualifier and serial are same
        @qualifier = options[:qualifier]
        @state = options[:state]
        @serial = options[:serial] || @qualifier
        @remote = options[:remote] ? true : false
        if is_remote?
          set_ip_and_port
          @serial = serial_no unless %w[unknown offline].include? @state
        end
      end

      def set_ip_and_port
        address = @qualifier.split(':')
        @ip_address = address.first
        @port = address.last
      end

      def is_remote?
        @remote || false
      end

      # Mapping of device status - used to provide a consistent status across platforms
      # @return (String) common status string
      def status
        {
          'device'         => :ok,
          'no device'      => :dead,
          'offline'        => :offline,
          'unauthorized'   => :unauthorized,
          'no permissions' => :no_permissions,
          'unknown' => :unknown
        }[@state]
      end

      def connect
        ADB.connect(@ip_address, @port)
      end

      def disconnect
        unless is_remote?
          raise DeviceAPI::Android::DeviceDisconnectedWhenNotARemoteDevice, "Asked to disconnect device #{qualifier} when it is not a remote device"
        end
        ADB.disconnect(@ip_address, @port)
      end

      # Return whether device is connected or not
      def is_connected?
        ADB.devices.any? { |device| device.include? qualifier }
      end

      def display_name
        device = Android::Devices.search_by_model(model)
        device.model unless device.nil?
      end

      # Return the device range
      # @return (String) device range string
      def range
        device = self.device
        model  = self.model

        return device if device == model
        "#{device}_#{model}"
      end

      # Return the serial number of device
      # @return (String) serial number
      def serial_no
        get_prop('ro.serialno')
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

      # Return the battery level
      # @return (String) device battery level
      def battery_level
        get_battery_info.level
      end

      # Is the device currently being powered?
      # @return (Boolean) true if it is being powered in some way, false if it is unpowered
      def powered?
        get_battery_info.powered
      end

      def block_package(package)
        if version < '5.0.0'
          ADB.block_package(qualifier, package)
        else
          ADB.hide_package(qualifier, package)
        end
      end

      # Return the device orientation
      # @return (String) current device orientation
      def orientation
        res = get_dumpsys('SurfaceOrientation')

        case res
        when '0', '2'
          :portrait
        when '1', '3'
          :landscape
        when nil
          raise StandardError, 'No output returned is there a device connected?', caller
        else
          raise StandardError, "Device orientation not returned got: #{res}.", caller
        end
      end

      # Install a specified apk
      # @param [String] apk string containing path to the apk to install
      # @return [Symbol, Exception] :success when the apk installed successfully, otherwise an error is raised
      def install(apk)
        raise StandardError, 'No apk specified.', caller if apk.empty?
        res = install_apk(apk)

        case res
        when 'Success'
          :success
        else
          raise StandardError, res, caller
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
          raise StandardError, "Unable to install 'package_name' Error Reported: #{res}", caller
        end
      end

      # Return the package name for a specified apk
      # @param [String] apk string containing path to the apk
      # @return [String, Exception] package name if it can be found, otherwise an error is raised
      def package_name(apk)
        @apk = apk
        result = get_app_props('package')['name']
        raise StandardError, 'Package name not found', caller if result.nil?
        result
      end

      def list_installed_packages
        packages = ADB.pm(qualifier, 'list packages')
        packages.split("\r\n")
      end

      # Return the app version number for a specified apk
      # @param [String] apk string containing path to the apk
      # @return [String, Exception] app version number if it can be found, otherwise an error is raised
      def app_version_number(apk)
        @apk = apk
        result = get_app_props('package')['versionName']
        raise StandardError, 'Version number not found', caller if result.nil?
        result
      end

      # Initiate monkey tests
      # @param [Hash] args arguments to pass on to ADB.monkey
      def monkey(args)
        ADB.monkey(qualifier, args)
      end

      # Capture screenshot on device
      # @param [Hash] args arguments to pass on to ADB.screencap
      def screenshot(args)
        ADB.screencap(qualifier, args)
      end

      # Get the IMEI number of the device
      # @return (String) IMEI number of current device
      def imei
        get_phoneinfo['Device ID']
      end

      # Get the memory information for the current device
      # @return [DeviceAPI::Android::Plugins::Memory] the memory plugin containing relevant information
      def memory
        get_memory_info
      end

      def battery
        get_battery_info
      end

      # Check if the devices screen is currently turned on
      # @return [Boolean] true if the screen is on, otherwise false
      def screen_on?
        power = get_powerinfo
        return true if power['mScreenOn'].to_s.casecmp('true').zero? || power['Display Power: state'].to_s.casecmp('on').zero?
        false
      end

      # Unlock the device by sending a wakeup command
      def unlock
        ADB.keyevent(qualifier, '26') unless screen_on?
      end

      # Return the DPI of the attached device
      # @return [String] DPI of attached device
      def dpi
        get_dpi(qualifier)
      end

      # Return the device type based on the DPI
      # @return [Symbol] :tablet or :mobile based upon the devices DPI
      def type
        get_dpi.to_i > 533 ? :tablet : :mobile
      end

      # Returns wifi status and access point name
      # @return [Hash] :status and :access_point
      def wifi_status
        ADB.wifi(qualifier)
      end

      def battery_info
        ADB.get_battery_info(qualifier)
      end

      # @param [String] command to start the intent
      # Return the stdout of executed intent
      # @return [String] stdout
      def intent(command)
        ADB.am(qualifier, command)
      end

      # Reboots the device
      def reboot
        ADB.reboot(qualifier, is_remote?)
      end

      # Returns disk status
      # @return [Hash] containing disk statistics
      def diskstat
        get_disk_info
      end

      # Returns the device uptime
      def uptime
        ADB.get_uptime(qualifier)
      end

      # Returns the Wifi IP address
      def ip_address
        interface = ADB.get_network_interface(qualifier, 'wlan0')
        if interface =~ /ip (.*) mask/
          Regexp.last_match[1]
        elsif interface =~ /inet addr:(.*)\s+Bcast/
          Regexp.last_match[1].strip
        end
      end

      # Returns the Wifi mac address
      def wifi_mac_address
        ADB.get_wifi_mac_address(qualifier)
      end

      def resolution
        res = ADB.dumpsys(qualifier, 'window | grep mUnrestrictedScreen')
        /^.* (.*)x(.*)$/.match(res.first)
      end

      private

      def get_network_info
        ADB.get_network_info(qualifier)
      end

      def get_disk_info
        @diskstat = DeviceAPI::Android::Plugin::Disk.new(qualifier: qualifier) unless @diskstat
        @diskstat.process_stats
      end

      def get_battery_info
        @battery = DeviceAPI::Android::Plugin::Battery.new(qualifier: qualifier) unless @battery
        @battery
      end

      def get_memory_info
        @memory = DeviceAPI::Android::Plugin::Memory.new(qualifier: qualifier) unless @memory
        @memory
      end

      def get_app_props(key)
        @app_props = AAPT.get_app_props(@apk) unless @app_props
        @app_props.each { |x| break x[key] }
      end

      def get_prop(key)
        @props = ADB.getprop(qualifier) if !@props || !@props[key]
        @props[key]
      end

      def get_dumpsys(key)
        @props = ADB.getdumpsys(qualifier)
        @props[key]
      end

      def get_powerinfo
        ADB.getpowerinfo(qualifier)
      end

      def get_phoneinfo
        ADB.getphoneinfo(qualifier)
      end

      def install_apk(apk)
        ADB.install_apk(apk: apk, qualifier: qualifier)
      end

      def uninstall_apk(package_name)
        ADB.uninstall_apk(package_name: package_name, qualifier: qualifier)
      end

      def get_dpi
        ADB.get_device_dpi(qualifier)
      end
    end

    class DeviceDisconnectedWhenNotARemoteDevice < StandardError
      def initialize(msg)
        super(msg)
      end
    end
  end
end
