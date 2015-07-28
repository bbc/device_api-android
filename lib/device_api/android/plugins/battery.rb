module DeviceAPI
  module Android
    module Plugin
	    class Battery
   	    attr_accessor :current_temp, :max_temp, :max_current, :voltage, :level, :health, :status

        def initialize(options = {})
          serial = options[:serial]
          props = ADB.get_battery_info(serial)
          self.current_temp   = props["temperature"]
          self.max_temp       = props["mBatteryMaxTemp"]
          self.max_current    = props["mBatteryMaxCurrent"]
          self.voltage        = props["voltage"]
          self.level          = props["level"]
          self.health         = props["health"]
          self.status         = props["status"]
        end
      end
    end
  end
end

