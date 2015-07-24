module DeviceAPI
  module Android
    module Plugin
      class Battery
   
   	attr_accessor :battery
   		def initialize(options = {})
   			@battery = {}
   			props = {}
   			serial = options[:serial]
          	info = options[:data] || ADB.dumpsys(serial, 'battery')
           	info.each do |i|
           		key = i.split(": ")[0].gsub(" ","_")
           		props[key] = "#{i.split(": ")[1]}"
          	end
          	@battery[:currentTemp] = props["temperature"]
          	@battery[:maxTemp] = props["mBatteryMaxTemp"]
          	@battery[:maxCurrent] = props["mBatteryMaxCurrent"]
          	@battery[:voltage] = props["voltage"]
          	@battery[:level] = props["level"]
          	@battery[:health] = props["health"]
          	@battery[:status] = props["status"]
   		end

      end
  	end
  end
end

