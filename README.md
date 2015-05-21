# DeviceAPI-Android

*DeviceAPI-Android* is the android implementation of device_api -- an initiative to allow full automation of device activities.

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

    devices = DeviceAPI::Android.devices

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

## Issues

If you plug in a device and adb shows the device as having no permissions as seen here:

            hive@hive-04:~$ adb devices
            List of devices attached
            ????????????	no permissions

This is caused by the current user not having permission to access the USB interface. To resolve this, copy the 51-android.rules file to the /etc/udev/rules.d/ directory and restart adb by using the folliowing command

            adb kill-server
            adb start-server

If, after copying the rules file to the correct location, you're still seeing the no permission message it may be due to the fact that the device does not have a rule setup for it. To add a new rule, type:

            lsusb

You should be presented with something similar to this:

            Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
            Bus 001 Device 020: ID 0e79:5009 Archos, Inc.
            Bus 001 Device 003: ID 05ac:8242 Apple, Inc. Built-in IR Receiver
            Bus 001 Device 006: ID 05ac:8289 Apple, Inc.
            Bus 001 Device 002: ID 0a5c:4500 Broadcom Corp. BCM2046B1 USB 2.0 Hub (part of BCM2046 Bluetooth)
            Bus 001 Device 011: ID 05c6:6765 Qualcomm, Inc.
            Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
            
The important thing to note here is the Vendor ID and Product ID for the device. In the case of the above, the device is a Tesco Hudl (showing as an Archos device) with the combinded ID of 0e79:5009 - 0e79 is the Vendor ID while 5009 is the Product ID. Open the 51-android.rules file and add the following line:

            SUBSYSTEM=="usb", ATTR{idVendor}=="0e79", ATTR{idProduct}=="5009", MODE="0666", OWNER="hive"

Change the Vendor and Product IDs where appropriate, also check that the owner matches the name of the account that will be running the Hive.

## License

*DeviceAPI-Android* is available to everyone under the terms of the MIT open source licence. Take a look at the LICENSE file in the code.

Copyright (c) 2015 BBC
