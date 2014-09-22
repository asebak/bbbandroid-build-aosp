# Component Path Configuration
export TARGET_PRODUCT := beagleboneblack
export ANDROID_INSTALL_DIR := $(patsubst %/,%, $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
export ANDROID_FS_DIR := $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/android_rootfs
export PATH :=$(PATH):$(ANDROID_INSTALL_DIR)/prebuilts/gcc/linux-x86/arm/arm-gnueabihf-4.7/bin
export CC_PREFIX :=arm-linux-gnueabihf-

kernel_not_configured := $(wildcard kernel/.config)

ifeq ($(TARGET_PRODUCT), beagleboneblack)
CLEAN_RULE = kernel_clean clean
rowboat: kernel_build
endif

kernel_build: droid
ifeq ($(strip $(kernel_not_configured)),)
ifeq ($(TARGET_PRODUCT), beagleboneblack)
	$(MAKE) -C kernel ARCH=arm am335x_evm_android_defconfig
endif
endif
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=$(CC_PREFIX) zImage
	$(MAKE) -C kernel ARCH=arm CROSS_COMPILE=$(CC_PREFIX) dtbs

kernel_clean:
	$(MAKE) -C kernel ARCH=arm  distclean

### DO NOT EDIT THIS FILE ###
include build/core/main.mk
### DO NOT EDIT THIS FILE ###

u-boot_build:
ifeq ($(TARGET_PRODUCT), beagleboneblack)
	$(MAKE) -C u-boot ARCH=arm am335x_evm_config
endif
	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=$(CC_PREFIX)

u-boot_clean:
	$(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=$(CC_PREFIX) distclean

# Make a tarball for the filesystem
fs_tarball: $(FS_GET_STATS)
	rm -rf $(ANDROID_FS_DIR)
	mkdir $(ANDROID_FS_DIR)
	cp -r $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/root/* $(ANDROID_FS_DIR)
	cp -r $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/ $(ANDROID_FS_DIR)
	(cd $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT); \
	 ../../../../build/tools/mktarball.sh ../../../host/linux-x86/bin/fs_get_stats android_rootfs . rootfs rootfs.tar.bz2)

# Make NFS tarball of the filesystem
nfs_tarball: $(FS_GET_STATS)
	rm -rf $(ANDROID_FS_DIR)
	mkdir $(ANDROID_FS_DIR)
	cp -r $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/root/* $(ANDROID_FS_DIR)
	cp -r $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT)/system/ $(ANDROID_FS_DIR)
	(cd $(ANDROID_INSTALL_DIR)/out/target/product/$(TARGET_PRODUCT); \
	tar cvjf nfs-rootfs.tar.bz2 android_rootfs)

rowboat_clean: $(CLEAN_RULE)

sdcard_build: rowboat u-boot_build fs_tarball
	$(ANDROID_INSTALL_DIR)/external/ti_android_utilities/make_distribution.sh $(ANDROID_INSTALL_DIR) $(TARGET_PRODUCT)
