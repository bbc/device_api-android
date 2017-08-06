# Encoding: utf-8

require 'open3'
require 'ostruct'
require 'device_api/execution'

# DeviceAPI - an interface to allow for automation of devices
module DeviceAPI
  # Android component of DeviceAPI
  module Android
    # Namespace for all methods encapsulating aapt calls
    class AAPT < DeviceAPI::Execution
      # Check to ensure that aapt has been setup correctly and is available
      # @return (Boolean) true if aapt is available, false otherwise
      def self.aapt_available?
        result = execute('which aapt')
        result.exit == 0
      end

      # Gets properties from the apk and returns them in a hash
      # @param apk path to the apk
      # @return (Hash) list of properties from the apk
      def self.get_app_props(apk)
        raise StandardError, 'aapt not found - please create a symlink in $ANDROID_HOME/tools' unless aapt_available?
        result = execute("aapt dump badging #{apk}")

        raise result.stderr if result.exit != 0

        result.stdout.scan(/(.*): (.*)/).map { |a, b| { a => Hash[b.split(' ').map { |c| c.tr('\'', '').split('=') }] } }
      end
    end
  end
end
