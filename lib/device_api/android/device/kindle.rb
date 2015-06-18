module DeviceAPI
  module Android
    class Kindle < Device
      # On non-Kindle devices, if a device is locked without a password (i.e. 'Swipe to unlock'), then
      # you can unlock that device by broadcasting a 'WakeUp' intent. On Kindle devices, this does not
      # work due to Amazons implementation of the Keyguard.
      def unlock
        ADB.keyevent(serial, '26') unless screen_on?
        ADB.swipe(serial, { x_from: 900, x_to: 300, y_from: 100, y_to: 100 } )
      end
    end
  end
end