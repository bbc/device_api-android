module DeviceAPI
  module Android
    module Plugin
      class Audio
        attr_reader :qualifier

        def initialize(options)
          @qualifier = options # [:serial]
        end

        def get_volume_steps
          audio = ADB.dumpsys(@qualifier, 'audio')
          vol_steps = audio.detect { |a| a.include?('volume steps:') }
          return nil if vol_steps.nil?

          vol_steps.scan(/volume steps: (.*)/).flatten.first.to_i
        end

        def get_current_volume
          system = get_system_volume
          volume = system.select { |a| a.include?('Current') }.first
          volume.scan(/Current: 2:\s(.*?),(:?.*)/).flatten.first.to_i
        end

        def is_muted?
          system = get_system_volume
          mute = system.select { |a| a.include?('Mute') }.first
          mute.scan(/Mute count: (.*)/).flatten.first.to_i > 0
        end

        def volume
          return 0 if is_muted?
          steps = get_volume_steps
          vol = get_current_volume
          ((vol.to_f / steps.to_f) * 100).to_i
        end

        def max_volume
          vol = get_current_volume
          steps = get_volume_steps

          change_volume(steps - vol, 24)

          get_current_volume == steps
        end

        def min_volume
          vol = get_current_volume
          change_volume(vol, 25)

          get_current_volume == 0
          # adb shell service call audio 4 i32 1 i32 0 i32 1
        end

        private

        def change_volume(op, key)
          op.times do
            ADB.keyevent(@qualifier, key)
          end
        end

        def get_system_volume
          audio = ADB.dumpsys(@qualifier, 'audio')
          index = audio.index('- STREAM_SYSTEM:')

          return nil if index.nil?

          audio[index + 1..index + 2]
        end
      end
    end
  end
end
