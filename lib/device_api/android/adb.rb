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

        raise ADBCommandError.new(result.stderr) if result.exit != 0

        lines = result.stdout.split("\n")
        results = []

        lines.shift # Drop the message line
        lines.each do |l|
          if /(.*)\t(.*)/.match(l)
            results.push(Regexp.last_match[1].strip => Regexp.last_match[2].strip)
          end
        end
        results
      end

      # Retrieve device state for a single device
      # @param serial serial number of device
      # @return (String) device state
      def self.get_state(serial)
        result = execute('adb get-state -s #{serial}')

        raise ADBCommandError.new(result.stderr) if result.exit != 0

        lines = result.stdout.split("\n")
        /(.*)/.match(lines.last)
        Regexp.last_match[0].strip
      end

      # Get the properties of a specified device
      # @param serial serial number of device
      # @return (Hash) hash containing device properties
      def self.getprop(serial)
        result = execute("adb -s #{serial} shell getprop")

        raise ADBCommandError.new(result.stderr) if result.exit != 0

        lines = result.stdout.split("\n")

        process_dumpsys('\[(.*)\]:\s+\[(.*)\]', lines)
      end

      # Get the 'input' information from dumpsys
      # @param serial serial number of device
      # @return (Hash) hash containing input information from dumpsys
      def self.getdumpsys(serial)
        lines = dumpsys(serial, 'input')
        process_dumpsys('(.*):\s+(.*)', lines)
      end

      # Get the 'iphonesubinfo' from dumpsys
      # @param serial serial number of device
      # @return (Hash) hash containing iphonesubinfo information from dumpsys
      def self.getphoneinfo(serial)
        lines = dumpsys(serial, 'iphonesubinfo')
        process_dumpsys('(.*) =\s+(.*)', lines)
      end

      # Get the 'battery' information from dumpsys
      # @param [String] serial serial number of device
      # @return [Hash] hash containing battery information from dumpsys
      def self.get_battery_info(serial)
        lines = dumpsys(serial, 'battery')
        process_dumpsys('(.*):\s+(.*)', lines)
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
      # @param [String] serial serial number of device
      # @return [Hash] hash containing power information from dumpsys
      def self.getpowerinfo(serial)
        lines = dumpsys(serial, 'power')
        process_dumpsys('(.*)=(.*)', lines)
      end

      def self.get_device_dpi(serial)
        lines = dumpsys(serial, 'window')
        dpi = nil
        lines.each do |line|
          if /sw(\d*)dp/.match(line)
            dpi = Regexp.last_match[1]
          end
        end
        dpi
      end

      # Returns the 'dumpsys' information from the specified device
      # @param serial serial number of device
      # @return (Array) array of results from adb shell dumpsys
      def self.dumpsys(serial, command)
        result = execute("adb -s #{serial} shell dumpsys #{command}")
        raise ADBCommandError.new(result.stderr) if result.exit != 0
        result.stdout.split("\n").map { |line| line.strip }
      end

      # Installs a specified apk to a specific device
      # @param [Hash] options the options used for installing an apk
      # @option options [String] :apk path to apk to install
      # @option options [String] :serial serial number of device
      # @return (String) return result from adb install command
      def self.install_apk(options = {})
        apk = options[:apk]
        serial = options[:serial]
        result = execute("adb -s #{serial} install #{apk}")

        raise ADBCommandError.new(result.stderr) if result.exit != 0

        lines = result.stdout.split("\n").map { |line| line.strip }
        # lines.each do |line|
        #  res=:success if line=='Success'
        # end

        lines.last
      end

      # Uninstalls a specified package from a specified device
      # @param [Hash] options the options used for uninstalling a package
      # @option options [String] :package_name package to uninstall
      # @option options [String] :serial serial number of device
      # @return (String) return result from adb uninstall command
      def self.uninstall_apk(options = {})
        package_name = options[:package_name]
        serial = options[:serial]
        result = execute("adb -s #{serial} uninstall #{package_name}")
        raise ADBCommandError.new(result.stderr) if result.exit != 0

        lines = result.stdout.split("\n").map { |line| line.strip }

        lines.last
      end

      # Returns the uptime of the specified device
      # @param serial serial number of device
      # @return (Float) uptime in seconds
      def self.get_uptime(serial)
        result = execute("adb -s #{serial} shell cat /proc/uptime")

        raise ADBCommandError.new(result.stderr) if result.exit != 0

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
      # @param serial serial number of device
      # @return (nil) Nil if successful, otherwise an error is raised
      def self.reboot(serial)
        result = execute("adb -s #{serial} reboot")
        raise ADBCommandError.new(result.stderr) if result.exit != 0
      end

      # Runs monkey testing
      # @param serial serial number of device
      # @param [Hash] args hash of arguments used for starting testing
      # @option args [String] :events (10000) number of events to run
      # @option args [String] :package name of package to run the tests against
      # @option args [String] :seed pass the seed number (optional)
      # @option args [String] :throttle throttle value (optional)
      # @example
      #   DeviceAPI::ADB.monkey( serial, :package => 'my.lovely.app' )
      def self.monkey(serial, args)

        events = args[:events] || 10000
        package = args[:package] or raise "package name not provided (:package => 'bbc.iplayer')"
        seed = args[:seed]
        throttle = args[:throttle]

        cmd = "adb -s #{serial} shell monkey -p #{package} -v #{events}"
        cmd = cmd + " -s #{seed}" if seed
        cmd = cmd + " -t #{throttle}" if throttle

        execute(cmd)
      end
      
      # Take a screenshot from the device
      # @param serial serial number of device
      # @param [Hash] args hash of arguments
      # @option args [String] :filename name (with full path) required to save the image
      # @example
      #   DeviceAPI::ADB.screenshot( serial, :filename => '/tmp/filename.png' )
      def self.screencap( serial, args )
        
        filename = args[:filename] or raise "filename not provided (:filename => '/tmp/myfile.png')"
        
        convert_carriage_returns = %q{perl -pe 's/\x0D\x0A/\x0A/g'}
        cmd = "adb -s #{serial} shell screencap -p | #{convert_carriage_returns} > #{filename}"
        
        execute(cmd)
      end

      # Returns wifi status and access point name
      # @param serial serial number of device
      # @example
      #   DeviceAPI::ADB.wifi(serial)
      def self.wifi(serial)
        result = execute("adb -s #{serial} shell dumpsys wifi | grep mNetworkInfo")
        if result.exit != 0
          raise ADBCommandError.new(result.stderr) 
        else
          result = {:status => result.stdout.match("state:(.*?),")[1].strip, :access_point => result.stdout.match("extra:(.*?),")[1].strip.gsub(/"/,'')}
        end
        result  
      end

      # Sends a key event to the specified device
      # @param [String] serial serial number of device
      # @param [String] keyevent keyevent to send to the device
      def self.keyevent(serial, keyevent)
        execute("adb -s #{serial} shell input keyevent #{keyevent}")
        raise ADBCommandError.new(result.stderr) if result.exit != 0
      end

      # Sends a swipe command to the specified device
      # @param [String] serial serial number of the device
      # @param [Hash] coords hash of coordinates to swipe from / to
      # @option coords [String] :x_from (0) Coordinate to start from on the X axis
      # @option coords [String] :x_to (0) Coordinate to end on on the X axis
      # @option coords [String] :y_from (0) Coordinate to start from on the Y axis
      # @option coords [String] :y_to (0) Coordinate to end on on the Y axis
      def self.swipe(serial, coords = {x_from: 0, x_to: 0, y_from: 0, y_to: 0 })
        execute("adb -s #{serial} shell input swipe #{coords[:x_from]} #{coords[:x_to]} #{coords[:y_from]} #{coords[:y_to]}")
        raise ADBCommandError.new(result.stderr) if result.exit != 0
      end

      # Starts intent using adb 
      # Returns stdout
      # @param serial serial number of device 
      # @param command -option activity 
      # @example
      # DeviceAPI::ADB.am(serial, "-a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings")
      def self.am(serial, command)
        result = execute("adb -s #{serial} shell am start #{command}")
        raise ADBCommandError.new(result.stderr) if result.exit != 0
        return result.stdout
      end
    end

    # ADB Error class
    class ADBCommandError < StandardError
      def initialize(msg)
        super(msg)
      end
    end


  end
end
