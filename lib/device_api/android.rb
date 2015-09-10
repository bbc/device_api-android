# Encoding: utf-8
require 'device_api/android/adb'
require 'device_api/android/device'
require 'device_api/android/signing'

# Load plugins
require 'device_api/android/plugins/memory'

# Load additional device types
require 'device_api/android/device/kindle'

module DeviceAPI
  module Android
    # Returns array of connected android devices
    def self.devices
      list = ADB.devices.map do |d|
        if d.keys.first && !d.keys.first.include?('?') && !d.values.first.include?('unauthorized')
          DeviceAPI::Android::Device.create( self.get_device_type(d.keys.first), { serial: d.keys.first, state: d.values.first } )
        end
      end
      list.compact
    end

    # Retrieve an Device object by serial id
    def self.device(serial)
      if serial.to_s.empty?
        raise DeviceAPI::BadSerialString.new("serial was '#{serial.nil? ? 'nil' : serial}'")
      end
      state = ADB.get_state(serial)
      DeviceAPI::Android::Device.create( self.get_device_type(serial),  { serial: serial, state: state })
    end

    # Return the device type used in determining which Device Object to create
    def self.get_device_type(serial)
      return :default if Device.new(serial: serial).manufacturer.nil?
      case Device.new(serial: serial).manufacturer.downcase
        when 'amazon'
          type = :kindle
        else
          type = :default
      end
      type
    end
  end

  # Serial error class
  class BadSerialString < StandardError
  end
end
