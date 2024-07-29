
VERSION = $(shell grep Version: deb/DEBIAN/control | cut -d' ' -f2)
# TODO: build module for all kernel versions
KVER ?= 6.1.21+
TARGET ?=  $(error TARGET not specified for deploy )

all: build/mrhat-battery_$(VERSION)-1_all.deb
	@true

build/mrhat-battery_$(VERSION)-1_all.deb : build/mrhat-battery.dtbo deb/DEBIAN/*
	mkdir -p build
	mkdir -p deb/boot/overlays/
	cp build/mrhat-battery.dtbo deb/boot/overlays/
	dpkg-deb -Zxz --root-owner-group --build deb build/mrhat-battery_$(VERSION)-1_all.deb

clean:
	rm -rf mrhat-battery/boot/  build/

build/mrhat-battery.dts.pre: mrhat-battery.dts
	mkdir -p build/
	cpp -nostdinc -undef -x assembler-with-cpp -I/var/chroot/buildroot/usr/src/linux-headers-$(KVER)/include -o build/mrhat-battery.dts.pre mrhat-battery.dts

build/mrhat-battery.dtbo: build/mrhat-battery.dts.pre
	mkdir -p build/
	dtc  -I dts -O dtb -o build/mrhat-battery.dtbo build/mrhat-battery.dts.pre

deploy: all
	rsync -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" -avhz --progress build/mrhat-battery_$(VERSION)-1_all.deb $(TARGET):/tmp/
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(TARGET) -- sudo dpkg -r mrhat-battery
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(TARGET) -- sudo dpkg -i /tmp/mrhat-battery_$(VERSION)-1_all.deb
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(TARGET) -- sudo sed -ri '/^\s*dtoverlay=mrhat-battery/d' /boot/config.txt
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(TARGET) -- "echo 'dtoverlay=mrhat-battery' | sudo tee -a /boot/config.txt"

quickdeploy: build/mrhat-battery.dtbo
	scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null build/mrhat-battery.dtbo $(TARGET):/tmp/
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(TARGET) -- sudo cp /tmp/mrhat-battery.dtbo /boot/overlays/

.PHONY: clean all deploy quickdeploy driver
