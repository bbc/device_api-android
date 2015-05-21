# Encoding: utf-8
require 'open3'
require 'ostruct'
require 'device_api/execution'

module DeviceAPI
  module Android
    class AAPT < DeviceAPI::Execution

      def self.aapt_available?
        begin
          result = execute('aapt')
          return true if result.exit == 2
        rescue
          # Some shells cause an error when a binary isn't found
          return false
        end
      end

      def self.get_app_props(apk)
        raise 'aapt not found - please create a symlink in $ANDROID_HOME/tools' unless aapt_available?
        result = execute("aapt dump badging #{apk}")

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
