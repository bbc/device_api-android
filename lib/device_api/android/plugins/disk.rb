module DeviceAPI
  module Android
    module Plugin
      class Disk
        attr_reader :qualifier
        def initialize(options = {})
          @qualifier = options[:qualifier]
        end

        def process_stats(options = {})
          disk_info = {}
          stats = options[:data] || ADB.dumpsys(@qualifier, 'diskstats')
          stats.each do |stat|
            if /(.*)-.*:\s(.*)\s\/\s([0-9]*[A-Z])\s[a-z]*\s=\s([0-9]*%)/.match(stat)
              disk_info["#{Regexp.last_match[1].downcase}_total"] = Regexp.last_match[3]
              disk_info["#{Regexp.last_match[1].downcase}_free"] = Regexp.last_match[4]
              disk_info["#{Regexp.last_match[1].downcase}_used"] = Regexp.last_match[2]
            elsif /(.*):\s(\S*)/.match(stat)
              disk_info[Regexp.last_match[1].downcase] = Regexp.last_match[2]
            end
          end
          disk_info
        end
      end
    end
  end
end
