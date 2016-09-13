module DeviceAPI
  module Android
    # Kindle specific device class
    class Kindle < Device
      # On non-Kindle devices, if a device is locked without a password (i.e. 'Swipe to unlock'), then
      # you can unlock that device by broadcasting a 'WakeUp' intent. On Kindle devices, this does not
      # work due to Amazons implementation of the Keyguard.
      def unlock
        ADB.keyevent(qualifier, '26') unless screen_on?
        if orientation == :landscape
          ADB.swipe(qualifier, { x_from: 500, y_from: 575, x_to: 500, y_to: 250 } )
        else
          ADB.swipe(qualifier, { x_from: 300, y_from: 900, x_to: 300, y_to: 600 } )
        end
      end
    end
  end
end