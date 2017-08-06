module DeviceAPI
  module Android
    # Plugins contain extra information about the attached device(s)
    module Plugin
      # Class used to provide information about process memory usage
      # and device memory usage
      class Memory
        # Class used for holding process information
        class MemInfo
          attr_reader :process, :memory, :pid
          def initialize(options = {})
            @process = options[:process]
            @memory  = options[:memory]
            @pid     = options[:pid]
          end
        end

        # Class used for storing process information
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

        attr_accessor :processes, :mem_info

        def initialize(options = {})
          @qualifier = options[:qualifier]
          info = options[:data] || ADB.dumpsys(@qualifier, 'meminfo')
          process_data(info)
        end

        def process_data(memory_info)
          groups = memory_info.chunk { |a| a == '' }.reject { |a, _| a }.map { |_, b| b }

          raise 'A different ADB result has been received' unless groups[1].first == 'Total PSS by process:'
          @processes = []
          process_total_pss_by_process(groups[1])
          process_ram_info(groups[4])
        end

        def update
          meminfo = ADB.dumpsys(@qualifier, 'meminfo')
          process_data(meminfo)
        end

        # Processes memory used by each running process
        def process_total_pss_by_process(data)
          data.each do |l|
            if /(.*):\s+(.*)\s+\(.*pid\s+(\S*).*\)/.match(l)
              @processes << MemInfo.new(process: Regexp.last_match[2], memory: Regexp.last_match[1], pid: Regexp.last_match[3])
            end
          end
        end

        # Processes memory used by the device
        def process_ram_info(data)
          ram_info = {}
          data.each do |l|
            if /Tuning:\s+(.*)/.match(l)
              ram_info['tuning'] = Regexp.last_match[1]
            elsif /(.*):\s(-?[0-9]*\s\S*)/.match(l)
              ram_info[Regexp.last_match[1].downcase] = Regexp.last_match[2]
            end
          end
          @mem_info = RAM.new(total: ram_info['total ram'], free: ram_info['free ram'], used: ram_info['used ram'], lost: ram_info['lost'], tuning: ram_info['tuning'])
        end
      end
    end
  end
end
