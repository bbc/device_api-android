
module DeviceAPI
  module Android
    # Namespace for all methods encapsulating adb calls
    class Signing < Execution
      def self.generate_keystore(options = {})
        keystore    = options[:keystore]
        alias_name  = options[:alias]     || 'HiveTesting'
        dname       = options[:dname]     || 'CN=hive'
        password    = options[:password]  || 'hivetesting'

        File.rename File.expand_path(keystore), "#{File.expand_path(keystore)}.backup" if File.exists?(File.expand_path(keystore))
        result = execute("keytool -genkey -noprompt -alias #{alias_name} -dname '#{dname}' -keystore #{keystore} -storepass #{password} -keypass #{password} -keyalg RSA -keysize 2048 -validity 10000")
        raise SigningCommandError.new(result.stderr) if result.exit != 0
        true
      end

      def self.sign_apk(options = {})
        apk               = options[:apk]
        alias_name        = options[:alias]             || 'HiveTesting'
        keystore          = options[:keystore]
        keystore_password = options[:keystore_password] || 'hivetesting'

        # Check to see if the APK has already been signed
        return false if is_apk_signed?(apk)
        result = execute("jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore #{File.expand_path(keystore)} -storepass #{keystore_password} #{apk} #{alias_name}")
        raise SigningCommandError.new(result.stderr) if result.exit != 0
        true
      end

      def self.is_apk_signed?(apk_path)
        #result = execute("aapt list #{apk_path}").lines.collect(&:strip).grep(/^META-INF\//)
        result = execute("aapt list #{apk_path} | grep '^META-INF.*\.RSA$'")
        return false if result.empty?
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