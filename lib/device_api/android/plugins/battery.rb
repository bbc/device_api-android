module DeviceAPI
  module Android
    module Plugin
      class Battery
        attr_reader :current_temp,
                    :max_temp,
                    :max_current,
                    :voltage,
                    :level,
                    :health,
                    :status,
                    :powered

        def initialize(options = {})
          qualifier = options[:qualifier]
          props = ADB.get_battery_info(qualifier)
          @current_temp   = props['temperature']
          @max_temp       = props['mBatteryMaxTemp']
          @max_current    = props['mBatteryMaxCurrent']
          @voltage        = props['voltage']
          @level          = props['level']
          @health         = props['health']
          @status         = props['status']
          @powered        = props['USB powered']
        end
      end
    end
  end
end
