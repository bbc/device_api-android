module DeviceAPI
  module Android
    # Kindle specific device class
    class Kindle < Device
      # On non-Kindle devices, if a device is locked without a password (i.e. 'Swipe to unlock'), then
      # you can unlock that device by broadcasting a 'WakeUp' intent. On Kindle devices, this does not
      # work due to Amazons implementation of the Keyguard.
      def unlock
        ADB.keyevent(qualifier, '26') unless screen_on?
        ADB.swipe(qualifier, swipe_coords)
      end

      def swipe_coords
        res = resolution
        x   = res[1].to_i
        y   = res[2].to_i
        if version.split('.').first.to_i < 5
          { x_from: x - 100, y_from: y / 2, x_to: x / 6, y_to: y / 2 }
        else
          { x_from: x / 2, y_from: y - 100, x_to: x / 2, y_to: y / 6 }
        end
      end
    end
  end
end
