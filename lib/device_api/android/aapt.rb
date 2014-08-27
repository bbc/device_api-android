# Encoding: utf-8
require 'open3'
require 'ostruct'
require 'device_api/execute_cmd'

module DeviceAPI
  module Android
    # Namespace for all methods encapsulating aapt calls
    class AAPT < Execute

      def self.aapt_available?
        result = DeviceAPI::Execute.execute('aapt')
        fail StandardError, 'aapt not found place a copy in $ANDROID_HOME/tools' if result.stdout.include?('No such file or directory')
      end

      def self.get_app_props(apk)
        aapt_available?
        result = DeviceAPI::Execute.execute("aapt dump badging #{apk}")

        fail result.stderr if result.exit != 0

        lines = result.stdout.split("\n")
        results = []
        lines.each do |l|
          if /(.*): (.*)/.match(l)
            # results.push(Regexp.last_match[1].strip => Regexp.last_match[2].strip)
            values = {}

            Regexp.last_match[2].strip.split(' ').each do |item| # split on an spaces
              item = item.to_s.tr('\'', '') # trim off any excess single quotes
              values[item.split('=')[0]] = item.split('=')[1] # split on the = and create a new hash
            end

            results << {Regexp.last_match[1].strip => values} # append the result tp new_result

          end
        end
        results
      end

    end
  end
end
