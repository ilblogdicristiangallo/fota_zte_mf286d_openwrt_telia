# fota_zte_mf286d_openwrt_telia
Shell script for sequential FOTA firmware updates on ZTE MF286D running OpenWrt. Automatically detects the current firmware version and runs only the required  update steps in the correct order, using ADB for file transfer and AT commands  over serial port to trigger the flash process.
