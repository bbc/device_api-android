module DeviceAPI
  module Android
    module Plugin
      class Battery
        attr_reader :current_temp, :max_temp, :max_current, :voltage, :level, :health, :status

        def initialize(options = {})
          serial = options[:serial]
          props = ADB.get_battery_info(serial)
          @current_temp   = props["temperature"]
          @max_temp       = props["mBatteryMaxTemp"]
          @max_current    = props["mBatteryMaxCurrent"]
          @voltage        = props["voltage"]
          @level          = props["level"]
          @health         = props["health"]
          @status         = props["status"]
        end
      end
    end
  end
end

