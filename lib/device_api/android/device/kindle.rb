module DeviceAPI
  module Android
    # Kindle specific device class
    class Kindle < Device
      # On non-Kindle devices, if a device is locked without a password (i.e. 'Swipe to unlock'), then
      # you can unlock that device by broadcasting a 'WakeUp' intent. On Kindle devices, this does not
      # work due to Amazons implementation of the Keyguard.
      def unlock
        ADB.keyevent(qualifier, '26') unless screen_on?

        return ADB.swipe(qualifier, {x_from: 900, y_from: 500, x_to: 300, y_to: 500}) if version.split('.').first.to_i < 5

        if orientation == :landscape
          coords = { x_from: 500, y_from: 750, x_to: 500, y_to: 250 }
        else
          coords = { x_from: 300, y_from: 900, x_to: 300, y_to: 600 }
        end

        ADB.swipe(qualifier, coords)
      end
    end
  end
end