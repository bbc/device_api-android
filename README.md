# DeviceAPI-Android
[![Build Status](https://travis-ci.org/bbc/device_api-android.svg?branch=master)](https://travis-ci.org/bbc/device_api-android)

*DeviceAPI-Android* is the android implementation of device_api -- an initiative to allow full automation of device activities. For a full list of release notes, see the [change log](CHANGELOG.md)

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

### Connecting and disconnecting from Remote Devices

You can connect to devices via their IP address and port number. The syntax is:

    DeviceAPI::Android.connect(<IP address>,<port number>=5555)

This should add a device to the already connected devices, which you can query with DeviceAPI::Android.devices. You can disconnect from a device like so:

    DeviceAPI::Android.disconnect(<IP address>,<port number>=5555)

Once connected, the IP address and port number combination becomes the serial for the device, and you can execute commands such as adb shell through specifying the IP address/port number instead of the serial number. For both Android.connect and Android.disconnect, if port number is not specified, and ip address is only specified, port number defaults to 5555. (Note that Android.disconnect doesn't automagically disconnect you from a connection with a port number that is not 5555 when it is called without a port argument)

You can also use the disconnect method on a Android device object, without any arguments to disconnect a device. It will throw an error if the device is not connected. 

    device.disconnect

You can use device.is_remote? to determine if the device is a remote device, e.g. it has a ipaddress and port as an adb serial, and can attempt to be connected to.

    device.is_remote?

### Error messages

Here are some of the errors you may encounter as well as a example of what can cause them:

`DeviceAPI::Android::ADB::DeviceAlreadyConnectedError` - raised when DeviceAPI::Android.connect is called on an currently connected device.

`DeviceAPI::Android::DeviceDisconnectedWhenNotARemoteDevice` - raised when we are attempting to call disconnect on a non-remote device.

`DeviceAPI::Android::ADBCommandError` - raised when we cannot connect to a device, e.g. adb times out.

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

#### APK Signing

An APK can be signed using *DeviceAPI*. To do so you can simply run:

    DeviceAPI::Android::Signing.sign_apk({apk: apk_path, resign: true})

If you don't already have a keystore setup then one will be created for you with some defaults already set. If you wish to setup a keystore using your own options you can do so using something like the following:

    DeviceAPI::Android::Signing.generate_keystore( { keystore: '~/new_kestore.keystore', password: 'new_password' } )

This allows you to setup a keystore with the options required by any testing framework

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
            
The important thing to note here is the Vendor ID and Product ID for the device. In the case of the above, the device is a Tesco Hudl (showing as an Archos device) with the combined ID of 0e79:5009 - 0e79 is the Vendor ID while 5009 is the Product ID. Open the 51-android.rules file and add the following line:

            SUBSYSTEM=="usb", ATTR{idVendor}=="0e79", ATTR{idProduct}=="5009", MODE="0666", OWNER="hive"

Change the Vendor and Product IDs where appropriate, also check that the owner matches the name of the account that will be running the Hive.

## License

*DeviceAPI-Android* is available to everyone under the terms of the MIT open source licence. Take a look at the LICENSE file in the code.

Copyright (c) 2016 BBC
