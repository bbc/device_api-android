# DeviceAPI - an interface to allow for automation of devices
module DeviceAPI
  # Android component of DeviceAPI
  module Android
    # Namespace for all methods encapsulating adb calls
    class Signing < Execution
      # Creates a keystore used for signing apks
      # @param [Hash] options options to pass through to keytool
      # @option options [String] :keystore ('~/.android/debug.keystore') full path to location to create keystore
      # @option options [String] :alias ('androiddebugkey') keystore alias name
      # @option options [String] :dname ('CN=hive') keystore dname
      # @option options [String] :password ('android') keystore password
      # @return [Boolean, Exception] returns true if a keystore is created, otherwise an exception is raised
      def self.generate_keystore(options = {})
        keystore    = options[:keystore]  || '~/.android/debug.keystore'
        alias_name  = options[:alias]     || 'androiddebugkey'
        dname       = options[:dname]     || 'CN=hive'
        password    = options[:password]  || 'android'

        result = execute("keytool -genkey -noprompt -alias #{alias_name} -dname '#{dname}' -keystore #{keystore} -storepass #{password} -keypass #{password} -keyalg RSA -keysize 2048 -validity 10000")
        raise SigningCommandError, result.stderr if result.exit != 0
        true
      end

      # Signs an apk using the specified keystore
      # @param [Hash] options options to pass through to jarsigner
      # @option options [String] :apk full path to the apk to sign
      # @option options [String] :alias ('androiddebugkey') alias of the keystore
      # @option options [String] :keystore ('~/.android/debug.keystore') full path to the location of the keystore
      # @option options [String] :keystore_password ('android') password required to open the keystore
      # @option options [Boolean] :resign if true then an already signed apk will be stripped of previous signing and resigned
      # @return [Boolean, Exception] return true if the apk is signed, false if the apk is already signed and resigning is anything other than true
      #   otherwise an exception is raised
      def self.sign_apk(options = {})
        apk               = options[:apk]
        alias_name        = options[:alias]             || 'androiddebugkey'
        keystore          = options[:keystore]          || '~/.android/debug.keystore'
        keystore_password = options[:keystore_password] || 'android'
        resign            = options[:resign]

        # Check to see if the APK has already been signed
        if is_apk_signed?(apk)
          return false unless resign
          unsign_apk(apk)
        end
        unless File.exist?(File.expand_path(keystore))
          generate_keystore(keystore: keystore,
                            password: keystore_password,
                            alias_name: alias_name)
        end

        result = execute("jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 -keystore #{File.expand_path(keystore)} -storepass #{keystore_password} #{apk} #{alias_name}")
        raise SigningCommandError, result.stderr if result.exit != 0
        true
      end

      # Checks to see if an apk has already been signed
      # @param [String] apk_path full path to apk to check
      # @return returns false if the apk is unsigned, true if it is signed
      def self.is_apk_signed?(apk_path)
        raise SigningCommandError, 'AAPT not available' unless DeviceAPI::Android::AAPT.aapt_available?
        result = execute("aapt list #{apk_path} | grep '^META-INF\/.*'")
        return false if result.stdout.empty?
        true
      end

      # Removes any previous signatures from an apk
      # @param [String] apk_path full path to the apk
      # @return [Boolean, Exception] returns true if the apk is successfully unsigned, otherwise an exception is raised
      def self.unsign_apk(apk_path)
        raise SigningCommandError, 'AAPT not available' unless DeviceAPI::Android::AAPT.aapt_available?
        file_list = execute("aapt list #{apk_path} | grep '^META-INF\/.*'")
        result    = execute("aapt remove #{apk_path} #{file_list.stdout.split(/\s+/).join(' ')}")
        raise SigningCommandError, result.stderr if result.exit != 0
        true
      end
    end

    # Signing error class
    class SigningCommandError < StandardError
      def initialize(msg)
        super(msg)
      end
    end
  end
end
