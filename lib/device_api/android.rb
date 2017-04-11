# Encoding: utf-8
require 'device_api/android/adb'
require 'device_api/android/device'
require 'device_api/android/signing'

# Load plugins
require 'device_api/android/plugins/audio'
require 'device_api/android/plugins/memory'
require 'device_api/android/plugins/battery'
require 'device_api/android/plugins/disk'

# Load additional device types
require 'device_api/android/device/kindle'
require 'device_api/android/device/samsung'

module DeviceAPI
  module Android
    # Returns array of connected android devices
    def self.devices
      ADB.devices.map do |d|
        if d.keys.first && !d.keys.first.include?('?')
          qualifier = d.keys.first
          remote = check_if_remote_device?(qualifier)
          DeviceAPI::Android::Device.create( self.get_device_type(d), { qualifier: qualifier, state: d.values.first, remote: remote} )
        end
      end.compact
    end

    # Retrieve an Device object by serial id
    def self.device(qualifier)
      if qualifier.to_s.empty?
        raise DeviceAPI::BadSerialString.new("Qualifier was '#{qualifier.nil? ? 'nil' : qualifier}'")
      end
      device = ADB.devices.select {|k| k.keys.first == qualifier}
      state = device.first[qualifier] || 'unknown'
      remote = check_if_remote_device?(qualifier)
      DeviceAPI::Android::Device.create( self.get_device_type({ :"#{qualifier}" => state}),  { qualifier:  qualifier, state: state, remote: remote })
    end

    def self.connect(ipaddress,port=5555)
      ADB.connect(ipaddress,port)
    end

    def self.disconnect(ipaddress,port=5555)
      ADB.disconnect(ipaddress,port)
    end

    def self.check_if_remote_device?(qualifier)
      begin
        ADB::check_ip_address(qualifier)
        true
      rescue ADBCommandError
        false 
      end 
    end

    # Return the device type used in determining which Device Object to create
    def self.get_device_type(options)
      return :default if ['unauthorized', 'offline', 'unknown'].include? options.values.first
      qualifier = options.keys.first
      state = options.values.first
      begin
        man = Device.new(qualifier: qualifier, state: state).manufacturer
      rescue DeviceAPI::DeviceNotFound
        return :default
      rescue => e
        puts "Unrecognised exception whilst finding device '#{qualifier}' (state: #{state})"
        puts e.message
        puts e.backtrace.inspect
        return :default
      end
      return :default if man.nil?
      case man.downcase
        when 'amazon'
          type = :kindle
        when 'samsung'
          type = :samsung
        else
          type = :default
      end
      type
    end

  # Serial error class
    class BadSerialString < StandardError
    end
  end
end
