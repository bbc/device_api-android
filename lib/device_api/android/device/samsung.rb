module DeviceAPI
  module Android
    # Samsung specific device class
    class Samsung < Device
      def initialize(options = {})
        super
        packages     = list_installed_packages
        multi_window = 'com.sec.android.app.FlashBarService'

        if packages.include?("package:#{multi_window}")
          # Stop the multi window function from running and block it
          intent("force-stop #{multi_window}")
          block_package(multi_window.to_s)
        end
      end
    end
  end
end
