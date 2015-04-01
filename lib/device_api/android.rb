# Encoding: utf-8
require 'device_api/android/adb'
require 'device_api/android/device'
require 'device_api/android/signing'

module DeviceAPI
  module Android
    # Returns array of connected android devices
    def self.devices
      ADB.devices.map do |d|
        if d.keys.first && !d.keys.first.include?('?')
          DeviceAPI::Android::Device.new(serial: d.keys.first, state: d.values.first)
        end
      end
    end

    # Retrieve an Device object by serial id
    def self.device(serial)
      if serial.to_s.empty?
        raise DeviceAPI::BadSerialString.new("serial was '#{serial.nil? ? 'nil' : serial}'")
      end
      state = ADB.get_state(serial)
      DeviceAPI::Android::Device.new(serial: serial, state: state)
    end
  end

  class BadSerialString < StandardError
  end
end
