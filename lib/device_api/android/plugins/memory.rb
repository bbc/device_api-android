module DeviceAPI
  module Android
    module Plugin
      class Memory

        class MemInfo
          attr_accessor :process, :memory, :pid
          def initialize(options = {})
            @process = options[:process]
            @memory = options[:memory]
            @pid = options[:pid]
          end
        end

        class RAM
          attr_accessor :total, :free, :used, :lost, :tuning
          def initialize(options = {})
            @total  = options[:total]
            @free   = options[:free]
            @used   = options[:used]
            @lost   = options[:lost]
            @tuning = options[:tuning]
          end
        end

        attr_accessor :info, :apps, :pss_by_process, :memory
        def initialize(options = {})
          @serial = options[:serial]
          @info = options[:data] || ADB.dumpsys(@serial, 'meminfo')

          groups = @info.split('')

          raise 'A different ADB result has been received' unless groups[1].first == 'Total PSS by process:'
          @pss_by_process = []
          process_total_pss_by_process(groups[1])
          process_ram_info(groups[4])
        end

        def process_total_pss_by_process(data)
          data.each do |l|
            if /(.*):\s+(.*)\s+\(.*pid\s+(\S*).*\)/.match(l)
              @pss_by_process << MemInfo.new(process: Regexp.last_match[2], memory: Regexp.last_match[1], pid: Regexp.last_match[3] )
            end
          end
        end

        def process_ram_info(data)
          ram_info = {}
          data.each do |l|
            if /Tuning:\s+(.*)/.match(l)
              ram_info['tuning'] = Regexp.last_match[1]
            elsif /(.*):\s+(.*)\s+\(.*\)/.match(l)
              ram_info[Regexp.last_match[1].downcase] = Regexp.last_match[2]
            end
          end
          @memory = RAM.new(total: ram_info['total ram'], free: ram_info['free ram'], used: ram_info['used ram'], lost: ram_info['lost'], tuning: ram_info['tuning'])
        end
      end
    end
  end
end