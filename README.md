# ubunut-esp8266-kaa
This reporitory contains a Docker image for developing ESP8266 applications for Kaa Project. It is based on the latest Ubuntu image. All tools necessary are included to build an application with a custom generated C SDK from Kaa Project. The image was created according to the [Kaa Project tutorial for the ESP8266](https://kaaproject.github.io/kaa/docs/v0.10.0/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/#flashing).

# Getting started

The Docker image basically contains all tools to compile and link your C project for the ESP8266. At the end, you will get two binary images which must be flashed to the ESP8266.

One problem with Docker is that it is a bit complicated to pass the serial port of the ESP8266 through to the Ubuntu running inside the image (at least on Windows as it is not possible to mount the serial port through Hyper-V). Thus, the flashing of the binary image onto the ESP8266 is done with tools running in the host system, not from inside Docker.

#### Experimental: (Linux only) Mount the serial port in the Docker image

*This is not tested, but might work. Please look on the internet for more information if this does not work. See [this post on stackoverflow](http://stackoverflow.com/questions/24225647/docker-any-way-to-give-access-to-host-usb-or-serial-device) to get started.*

Mounting the serial port in the Docker image might work under Linux if the /dev/bus/usb directory is mounted in the Docker VM. To do this, add "-v /dev/bus/usb:/dev/bus/usb" to the docker run command. It might be necessary to change the path to the local *usb* device in the */dev/* folder.


## Prerequisites

* This image has been created and tested with Windows 10. Since it is a Docker image, it should run on different operating systems as well.
* Make sure that the drive where your source project lies is shared with docker
 * Goto *Docker settings -> Shared drives* and share the corresponding drive.
* The standard user in the image is *esp* with password *esp*
 * This user is allowed to run commands using sudo
 * You can also switch to the user *root* with password *root* 

### (Optional) Getting started with the example code
If you don't have a project on your own, yet, you can try this guide with the samples app from the Kaa Project git repository.

#### Get the example from the git repository
You need to download or **git clone** the kaa repository first:

```
Git clone URL: git clone https://github.com/kaaproject/kaa.git
```

The branch *develop-1.0.0* (at commit 4e39525fc7a082457dfc4a5e8968f51665594c94) worked well. If you run into problems with the most current commit on the repository, you can try to switch back to the commit above.

The sample app resides in the folder [doc/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/attach/esp8266-sample/] (https://github.com/kaaproject/kaa/tree/develop-1.0.0/doc/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/attach/esp8266-sample/)

## Create the endpoint SDK
Create the **C SDK** for the desired endpoint in Kaa Project. Then, create a folder named "libs/kaa" in the project folder (the folder which is mounted under /opt/app). Copy the contents of the SDK into the folder "libs/kaa"

## Run the Docker image
The only configuration needed to run the image is the path pointing to where your project resides.

If you have your own project, run the following command. Make sure to replace `<Path to your project's root>` with the path to the project on your local hard drive. 

```
docker run -v "<Path to your project's root>:/opt/app" -ti kaans/ubuntu-esp8266-kaa-git
```

If you want to compile the sample project (as downloaded above), run the following command. Make sure to replace `<Path to cloned git repository>` with the path to the root of the downloaded or cloned repository on your local hard drive. 

```
docker run -v "<Path to cloned git repository>\kaa\doc\Programming-guide\Using-Kaa-endpoint-SDKs\C\SDK-ESP8266\attach\esp8266-sample:/opt/app" -ti kaans/ubuntu-esp8266-kaa-git
```

-> Now your sample project is mounted to /opt/app

## Compile the project

Run the following commands as **user esp**:

```
cd /opt/app
rm -rf build
mkdir -p build
cd build
cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=../libs/kaa/toolchains/esp8266.cmake \
        -DKAA_PLATFORM=esp8266 \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DWITH_EXTENSION_CONFIGURATION=ON \
        -DWITH_EXTENSION_EVENT=OFF \
        -DWITH_EXTENSION_NOTIFICATION=OFF \
        -DWITH_EXTENSION_LOGGING=ON \
        -DWITH_EXTENSION_USER=OFF \
        -DWITH_EXTENSION_PROFILE=OFF \
        -DWITH_ENCRYPTION=OFF \
        -DKAA_MAX_LOG_LEVEL=3
make
```

Note that the configuration above builds the project only with the extensions *configuration* and *logging* enabled. You can adjust the parameters passed to the `cmake` command to enable/disable extensions or encryption.

Be aware that enabling all extensions might use too much memory and the linker might complain with something similar to the following while not linking your image:

```
...: kaa_demo section `.text' will not fit in region `iram1_0_seg'
...: region `iram1_0_seg' overflowed by 24817 bytes
```

If this error occurs you need to disable some of the extensions. The example above does work as a minimal configuration. Try to enable the extensions step-by-step and see which ones fit and which don't.

## Convert the elf image to binary image for ESP8266

Goto the directory /opt/app and execute the `esptool.py` command to convert the elf image to the binary image for ESP8266.

If you use the sample app, execute the following:

```
esptool.py elf2image build/kaa_demo
```

If you use your own project, execute the following command. Note that you first need to change the `<image_name>` to the name of the elf image generated by your project.

```
esptool.py elf2image build/<image_name>
```

Now you have two images which are waiting to be flashed onto your ESP8266!

## Flash the firmware

After finishing the previous steps, you should now have two images:
* `<image_name>-0x00000.bin`
* `<image_name>-0x40000.bin`

Depending on your operating system, there are several [ways to flash the image](https://nodemcu.readthedocs.io/en/master/en/flash/):

### Windows

On Windows, one easy way to flash the images is the program [NodeMCU flasher](https://github.com/nodemcu/nodemcu-flasher). Just download the repository and execute the *ESP8266Flasher.exe* file in the *Win32* or *Win64* folders.

After starting the program, switch to the *Config* tab. Now select the path to **both** images, one in each line. For the image ending with *0x00000.bin* choose *0x00000* as the starting address on the right most dropdown menu. Do the same for the image ending with *0x40000.bin*, but choose *0x40000* as the starting address.

Switch back to the tab *Operation*, select the COM port where the ESP8266 is connected to, and press the *Flash* button.

### Linux

On Linux, you can use the [esptool.py](https://github.com/espressif/esptool) program to flash the image. Execute the following command from the directory in which the images reside. Make sure to adjust the `<image_name>` to the name of your images.

```
sudo esptool.py write_flash 0x00000 <image_name>-0x00000.bin 0x40000 <image_name>-0x40000.bin
```

If you managed to mount the serial port in the Docker image, you can try flashing the EP8266 from inside the Docker image with the esptool.

## Finally, your program should now be running

If all worked well, your image is now flashed to the ESP8266. Restart the ESP8266 and your program should start running.

Make sure to monitor the serial output of the ESP8266 to verify it is running and to be notified about any errors.

# Useful information

Here are some links with some useful information:

* [v0.10.0 ESP8266 C tutorial] (https://kaaproject.github.io/kaa/docs/v0.10.0/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/)
* [pre-v0.10.0 ESP8266 C tutorial] (http://docs.kaaproject.org/pages/viewpage.action?pageId=16417635)
* [C SDK API docs] (http://kaaproject.github.io/kaa/autogen-docs/client-c/v0.10.0/files.html)

Actually both the current (v0.10.0) and previous ESP8266 tutorials help to get the code running.

## Print memory listing of generated ELF file
This command prints out the memory listing of the elf image to the file *listing.txt*. It can help in finding where your program resides (ROM or RAM). Also it allows to analyze which parts of the code residing in the RAM might be relocatable to the ROM.

```
xtensa-lx106-elf-objdump -x kaa_demo > listing.txt
```

# Notes about the Docker image

Two things had to be changed in order to make the instructions work as written in the [v0.10.0 ESP8266 C tutorial] (https://kaaproject.github.io/kaa/docs/v0.10.0/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/).

## esptool.py
The esptool failed to generate the final binary images from the elf because it could not parse the output of the ... correctly. For some sections, the address was empty and thus the parsing of the address failed. The esptool has been adjusted so that it skips these sections and prints out a warning `Line with field ... has wrong format`.

The program does seem to work nevertheless.

## The memory map for the linker

The sections `.literal.*` and `.text.*` have been moved from iram1_0 to irom0_0. This effectively moves these sections from RAM to ROM.

This step was necessary because otherwise the image would have been to big to fit in memory with an error similar to this:

```
...: kaa_demo section `.text' will not fit in region `iram1_0_seg'
...: region `iram1_0_seg' overflowed by 24817 bytes
```

This leaves at least some room for custom applications. But it seems that a lot of memory is used by the SDK and the other libraries around it.
