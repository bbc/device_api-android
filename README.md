# device_api-android

device_api-android is the android implementation of device_api -- an initiative to allow full automation of device activities.

## Dependencies

device_api-android shells out to a number of android command line tools. You will need to make sure the android sdk is installed and you have the following commands on your path:
* adb
* aapt

## Using the gem

Add the device_api-android gem to your gemfile -- this will automatically bring in the device_api base gem on which the android gem is built.

    gem 'device_api-android'
  
You'll need to require the library in your code:

    require 'device_api/android'

Try connecting an android device with usb, and run:

    device = DeviceAPI::Android.devices

You might need to set your device to developer mode, and turn on usb debugging so that the android debug bridge can detect your device.

### Detecting devices

There are two methods for detecting devices:
    DeviceAPI::Android.devices 
This returns an array of objects representing the connected devices. You get an empty array if there are no connected devices.
    DeviceAPI::Android.device(serial_id)
    
This looks for a device with a matching serial_id and returns a single device object.

### Device object

When device-api detects a device, it returns a device object that lets you interact with and query the device with various android tools.

For example:
    device = DeviceAPI::Android.device(serial_id)
    device.serial # "01498A0004005015"
    device.model # "Galaxy Nexus"

#### Device orientation

device.orientation # :landscape / :portrait

#### Install/uninstall apk

    device.install('location/apk_to_install.apk') # will install the apk on the device
    device.uninstall('my.package.name') # will uninstall the package matching the package name

### Package details

    device.package_name('app.apk') # returns some.package.name
    device.app_version_number('app.apk') # returns v#.#.#

## Testing

device_api-android is defended with unit and integration level rspec tests. You can run the tests with:
    bundle exec rspec
