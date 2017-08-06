# Encoding: utf-8

# TODO: create new class for aapt that will get the package name from an apk using: JitG
# aapt dump badging packages/bbciplayer-debug.apk
require 'open3'
require 'ostruct'
require 'device_api/execution'

# DeviceAPI - an interface to allow for automation of devices
module DeviceAPI
  # Android component of DeviceAPI
  module Android
    # Namespace for all methods encapsulating adb calls
    class ADB < Execution
      # Returns an array representing connected devices
      # DeviceAPI::ADB.devices #=> { '1232132' => 'device' }
      # @return (Array) list of attached devices
      def self.devices
        result = execute_with_timeout_and_retry('adb devices')

        raise ADBCommandError, result.stderr if result.exit != 0
        result.stdout.scan(/(.*)\t(.*)/).map { |a, b| { a.strip => b.strip } }
      end

      # Retrieve device state for a single device
      # @param qualifier qualifier of device
      # @return (String) device state
      def self.get_state(qualifier)
        result = execute("adb -s #{qualifier} get-state")

        raise ADBCommandError, result.stderr if result.exit != 0

        lines = result.stdout.split("\n")
        /(.*)/.match(lines.last)
        Regexp.last_match[0].strip
      end

      # Get the properties of a specified device
      # @param qualifier qualifier of device
      # @return (Hash) hash containing device properties
      def self.getprop(qualifier)
        result = shell(qualifier, 'getprop')

        lines = result.stdout.encode('UTF-16', 'UTF-8', invalid: :replace, replace: '').encode('UTF-8', 'UTF-16').split("\n")

        process_dumpsys('\[(.*)\]:\s+\[(.*)\]', lines)
      end

      # Get the 'input' information from dumpsys
      # @param qualifier qualifier of device
      # @return (Hash) hash containing input information from dumpsys
      def self.getdumpsys(qualifier)
        lines = dumpsys(qualifier, 'input')
        process_dumpsys('(.*):\s+(.*)', lines)
      end

      # Get the 'iphonesubinfo' from dumpsys
      # @param qualifier qualifier of device
      # @return (Hash) hash containing iphonesubinfo information from dumpsys
      def self.getphoneinfo(qualifier)
        lines = dumpsys(qualifier, 'iphonesubinfo')
        process_dumpsys('(.*) =\s+(.*)', lines)
      end

      # Get the 'battery' information from dumpsys
      # @param [String] qualifier qualifier of device
      # @return [Hash] hash containing battery information from dumpsys
      def self.get_battery_info(qualifier)
        lines = dumpsys(qualifier, 'battery')
        process_dumpsys('(.*):\s+(.*)', lines)
      end

      def self.get_network_interface(qualifier, interface)
        result = shell(qualifier, "ifconfig #{interface}")
        result.stdout
      end

      # Get the network information
      def self.get_network_info(qualifier)
        lines = shell(qualifier, 'netcfg')
        lines.stdout.split("\n").map do |a|
          b = a.split(' ')
          { name: b[0], ip: b[2].split('/')[0], mac: b[4] }
        end
      end

      def self.get_wifi_mac_address(qualifier)
        lines = shell(qualifier, 'ip address')
        lines = lines.to_s.gsub(/\r\n/, '') if lines
        match_data = lines.match(/wlan0: .+? (\w{2}:\w{2}:\w{2}:\w{2}:\w{2}:\w{2})/)
        match_data[1] if match_data
      end

      # Processes the results from dumpsys to format them into a hash
      # @param [String] regex_string regex string used to separate the results from the keys
      # @param [Array] data data returned from dumpsys
      # @return [Hash] hash containing the keys and values as distinguished by the supplied regex
      def self.process_dumpsys(regex_string, data)
        props = {}
        regex = Regexp.new(regex_string)
        data.each do |line|
          if regex.match(line)
            props[Regexp.last_match[1]] = Regexp.last_match[2]
          end
        end

        props
      end

      # Get the 'power' information from dumpsys
      # @param [String] qualifier qualifier of device
      # @return [Hash] hash containing power information from dumpsys
      def self.getpowerinfo(qualifier)
        lines = dumpsys(qualifier, 'power')
        process_dumpsys('(.*)=(.*)', lines)
      end

      def self.get_device_dpi(qualifier)
        lines = dumpsys(qualifier, 'window')
        dpi = nil
        lines.each do |line|
          dpi = Regexp.last_match[1] if /sw(\d*)dp/.match(line)
        end
        dpi
      end

      # Returns the 'dumpsys' information from the specified device
      # @param qualifier qualifier of device
      # @return (Array) array of results from adb shell dumpsys
      def self.dumpsys(qualifier, command)
        result = shell(qualifier, "dumpsys #{command}")
        result.stdout.split("\n").map(&:strip)
      end

      # Installs a specified apk to a specific device
      # @param [Hash] options the options used for installing an apk
      # @option options [String] :apk path to apk to install
      # @option options [String] :qualifier qualifier of device
      # @return (String) return result from adb install command
      def self.install_apk(options = {})
        options[:action] = :install
        change_apk(options)
      end

      # Uninstalls a specified package from a specified device
      # @param [Hash] options the options used for uninstalling a package
      # @option options [String] :package_name package to uninstall
      # @option options [String] :qualifier qualifier of device
      # @return (String) return result from adb uninstall command
      def self.uninstall_apk(options = {})
        options[:action] = :uninstall
        change_apk(options)
      end

      def self.change_apk(options = {})
        package_name = options[:package_name]
        apk = options[:apk]
        qualifier = options[:qualifier]
        action = options[:action]

        case action
        when :install
          command = "adb -s #{qualifier} install #{apk}"
        when :uninstall
          command = "adb -s #{qualifier} uninstall #{package_name}"
        else
          raise ADBCommandError, 'No action specified'
        end

        result = execute(command)

        raise ADBCommandError, result.stderr if result.exit != 0

        lines = result.stdout.split("\n").map(&:strip)

        lines.last
      end

      # Returns the uptime of the specified device
      # @param qualifier qualifier of device
      # @return (Float) uptime in seconds
      def self.get_uptime(qualifier)
        result = shell(qualifier, 'cat /proc/uptime')

        lines = result.stdout.split("\n")
        uptime = 0
        lines.each do |l|
          if /([\d.]*)\s+[\d.]*/.match(l)
            uptime = Regexp.last_match[0].to_f.round
          end
        end
        uptime
      end

      # Reboots the specified device
      # Remote devices are rebooted and disconnected from system
      # @param qualifier qualifier of device
      # @return (nil) Nil if successful, otherwise an error is raised
      def self.reboot(qualifier, remote)
        if remote
          begin
            system("adb -s #{qualifier} reboot &")
            disconnect(qualifier.split(':').first)
          rescue => e
            raise ADBCommandError, e
          end
        else
          result = execute("adb -s #{qualifier} reboot && adb -s #{qualifier} wait-for-device shell 'while [[ $(getprop dev.bootcomplete | tr -d '\r') != 1 ]    ]; do sleep 1; printf .; done'")
          raise ADBCommandError, result.stderr if result.exit != 0
        end
      end

      # Runs monkey testing
      # @param qualifier qualifier of device
      # @param [Hash] args hash of arguments used for starting testing
      # @option args [String] :events (10000) number of events to run
      # @option args [String] :package name of package to run the tests against
      # @option args [String] :seed pass the seed number (optional)
      # @option args [String] :throttle throttle value (optional)
      # @example
      #   DeviceAPI::ADB.monkey( qualifier, :package => 'my.lovely.app' )
      def self.monkey(qualifier, args)
        events = args[:events] || 10_000
        (package = args[:package]) || raise("package name not provided (:package => 'bbc.iplayer')")
        seed = args[:seed]
        throttle = args[:throttle]

        cmd = "monkey -p #{package} -v #{events}"
        cmd += " -s #{seed}" if seed
        cmd += " -t #{throttle}" if throttle

        shell(qualifier, cmd)
      end

      # Take a screenshot from the device
      # @param qualifier qualifier of device
      # @param [Hash] args hash of arguments
      # @option args [String] :filename name (with full path) required to save the image
      # @example
      #   DeviceAPI::ADB.screenshot( qualifier, :filename => '/tmp/filename.png' )
      def self.screencap(qualifier, args)
        (filename = args[:filename]) || raise("filename not provided (:filename => '/tmp/myfile.png')")

        if getprop(qualifier)['ro.build.version.release'].to_i < 7
          convert_carriage_returns = %q(perl -pe 's/\x0D\x0A/\x0A/g')
          cmd = "screencap -p | #{convert_carriage_returns} > #{filename}"
        else
          cmd = "screencap -p > #{filename}"
        end

        shell(qualifier, cmd)
      end

      # Connects to remote android device
      # @param [String] ip_address
      # @param [String] port
      # @example
      #  DeviceAPI::ADB.connect(ip_address, port)
      def self.connect(ip_address, port = 5555)
        ip_address_and_port = "#{ip_address}:#{port}"
        check_ip_address(ip_address_and_port)
        cmd = "adb connect #{ip_address_and_port}"
        result = execute(cmd)
        if result.stdout.to_s =~ /.*already connected to.*/
          raise DeviceAlreadyConnectedError, "Device #{ip_address_and_port} already connected"
        else
          unless result.stdout.to_s =~ /.*connected to.*/
            raise ADBCommandError, "Unable to adb connect to #{ip_address_and_port} result was: #{result.stdout}"
          end
        end
      end

      # Disconnects from remote android device
      # @param [String] ip_address
      # @param [String] port
      # @example
      #  DeviceAPI::ADB.disconnect(ip_address, port)
      def self.disconnect(ip_address, port = 5555)
        ip_address_and_port = "#{ip_address}:#{port}"
        check_ip_address(ip_address_and_port)
        cmd = "adb disconnect #{ip_address_and_port}"
        result = execute(cmd)
        unless result.exit == 0
          raise ADBCommandError, "Unable to adb disconnect to #{ip_address_and_port} result was: #{result.stdout}"
        end
      end

      # Returns wifi status and access point name
      # @param qualifier qualifier of device
      # @example
      #   DeviceAPI::ADB.wifi(qualifier)
      def self.wifi(qualifier)
        result = shell(qualifier, 'dumpsys wifi | grep mNetworkInfo')

        { status: result.stdout.match('state:(.*?),')[1].strip, access_point: result.stdout.match('extra:(.*?),')[1].strip.delete('"') }
      end

      # Sends a key event to the specified device
      # @param [String] qualifier qualifier of device
      # @param [String] keyevent keyevent to send to the device
      def self.keyevent(qualifier, keyevent)
        shell(qualifier, "input keyevent #{keyevent}").stdout
      end

      # ADB Shell command
      # @param [String] qualifier qualifier of device
      # @param [String] command command to execute
      def self.shell(qualifier, command)
        result = execute("adb -s '#{qualifier}' shell #{command}")
        if result.exit != 0
          case result.stderr
          when /^error: device unauthorized./
            raise DeviceAPI::UnauthorizedDevice, result.stderr
          when /^error: device not found/
            raise DeviceAPI::DeviceNotFound, result.stderr
          # ADB.get_network_info on android > 7 behave differently
          #   On linux exit code is 127
          #   On MAC exit code is 0
          # Caught here to give get_network_info consistent response
          when /^\/system\/bin\/sh: netcfg: not found/
            return result
          else
            raise ADBCommandError, result.stderr
          end
        end

        result
      end

      # Sends a swipe command to the specified device
      # @param [String] qualifier qualifier of the device
      # @param [Hash] coords hash of coordinates to swipe from / to
      # @option coords [String] :x_from (0) Coordinate to start from on the X axis
      # @option coords [String] :x_to (0) Coordinate to end on on the X axis
      # @option coords [String] :y_from (0) Coordinate to start from on the Y axis
      # @option coords [String] :y_to (0) Coordinate to end on on the Y axis
      def self.swipe(qualifier, coords = { x_from: 0, y_from: 0, x_to: 0, y_to: 0 })
        shell(qualifier, "input swipe #{coords[:x_from]} #{coords[:y_from]} #{coords[:x_to]} #{coords[:y_to]}").stdout
      end

      # Starts intent using adb
      # Returns stdout
      # @param qualifier qualifier of device
      # @param command -option activity
      # @example
      # DeviceAPI::ADB.am(qualifier, "start -a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings")
      def self.am(qualifier, command)
        shell(qualifier, "am #{command}").stdout
      end

      # Package manager commands
      # @param qualifier qualifier of device
      # @param command command to issue to the package manager
      # @example DeviceAPI::ADB.pm(qualifier, 'list packages')
      def self.pm(qualifier, command)
        shell(qualifier, "pm #{command}").stdout
      end

      # Blocks a package, used on Android versions less than KitKat
      # Returns boolean
      # @param qualifier qualifier of device
      # @param package to block
      def self.block_package(qualifier, package)
        result = pm(qualifier, "block #{package}")
        result.include?('true')
      end

      # Blocks a package on KitKat and above
      # Returns boolean
      # @param qualifier qualifier of device
      # @param package to hide
      def self.hide_package(qualifier, package)
        result = pm(qualifier, "hide #{package}")
        result.include?('true')
      end

      def self.check_ip_address(ip_address_and_port)
        unless ip_address_and_port =~ /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}):[0-9]+\Z/
          raise ADBCommandError, "Invalid IP address and port #{ip_address_and_port}"
        end
      end
    end

    # ADB Error class
    class ADBCommandError < StandardError
      def initialize(msg)
        super(msg)
      end
    end
    class DeviceAlreadyConnectedError < ADBCommandError
      def initialize(msg)
        super(msg)
      end
    end
  end
end
