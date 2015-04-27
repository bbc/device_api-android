
module DeviceAPI
  module Android
    # Namespace for all methods encapsulating adb calls
    class Signing < Execution
      def self.generate_keystore(options = {})
        keystore    = options[:keystore]  || '~/.android/debug.keystore'
        alias_name  = options[:alias]     || 'androiddebugkey'
        dname       = options[:dname]     || 'CN=hive'
        password    = options[:password]  || 'android'

        result = execute("keytool -genkey -noprompt -alias #{alias_name} -dname '#{dname}' -keystore #{keystore} -storepass #{password} -keypass #{password} -keyalg RSA -keysize 2048 -validity 10000")
        raise SigningCommandError.new(result.stderr) if result.exit != 0
        true
      end

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
        generate_keystore({ keystore: keystore, password: keystore_password, alias_name: alias_name }) unless File.exists?(File.expand_path(keystore))
        result = execute("jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 -keystore #{File.expand_path(keystore)} -storepass #{keystore_password} #{apk} #{alias_name}")
        raise SigningCommandError.new(result.stderr) if result.exit != 0
        true
      end

      def self.is_apk_signed?(apk_path)
        result = execute("aapt list #{apk_path} | grep '^META-INF.*\.RSA$'")
        return false if result.stdout.empty?
        true
      end

      def self.unsign_apk(apk_path)
        file_list = execute("aapt list #{apk_path} | grep '^META-INF.*\.RSA$'")
        result = execute("aapt remove #{apk_path} #{file_list.stdout.split(/\s+/).join(' ')}")
        raise SigningCommandError.new(result.stderr) if result.exit != 0
        true
       end
    end

    class SigningCommandError < StandardError
      def initialize(msg)
        super(msg)
      end
    end
  end
end