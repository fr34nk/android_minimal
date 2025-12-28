#!/bin/bash

# Configuration
AVD_NAME="FastDevice"
SDK_ID="system-images;android-33;google_apis;x86_64"
AVD_PATH="$HOME/.android/avd/$AVD_NAME.avd"

check_status() {
    if [ $? -ne 0 ]; then
        echo "Executing: $1"
        echo "Error: $2"
        exit 1
    fi
}

download_image() {
    echo "Executing: download_image"
    # Ensure the system image exists before creating the AVD
    sdkmanager --install "$SDK_ID"
    check_status "download_image" "Failed to download system image"
}

create_avd_minimal() {
    echo "Executing: create_avd_minimal"
    # 'echo no' handles the "Do you wish to create a custom hardware profile" prompt
    echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$SDK_ID" --force
    check_status "create_avd_minimal" "Failed to create AVD"
}

optimize_settings() {
    echo "Executing: optimize_settings"
    # Append high-performance settings to the config.ini
    if [ -f "$AVD_PATH/config.ini" ]; then
        cat <<EOF >> "$AVD_PATH/config.ini"
hw.ramSize=2048
hw.cpu.ncore=4
hw.gpu.enabled=yes
hw.gpu.mode=host
hw.lcd.density=160
hw.lcd.height=800
hw.lcd.width=480
vm.heapSize=256
disk.dataPartition.size=800M
hw.keyboard=yes
EOF
    else
        check_status "optimize_settings" "config.ini not found at $AVD_PATH"
    fi
}


start_fast_emulator() {
    echo "Executing: start_fast_emulator"
    # -no-snapshot-save: Speeds up closing
    # -no-boot-anim: Disables the Android boot animation for faster UI availability
    # -no-audio: Reduces CPU overhead
    emulator -avd "$AVD_NAME" -no-boot-anim -no-audio -netfast &
    check_status "start_fast_emulator" "Failed to launch emulator"
}

download_create_emulator () {

  # --- Execution ---
  download_image
  create_avd_minimal
  optimize_settings
  start_fast_emulator

  echo "------------------------------------------------"
  echo "AVD '$AVD_NAME' is booting with optimized settings."

}

transfer_file () {
  source_file=$1
  target_dir=${2:-storage/self/primary/Download/}
  adb push $source_file $target_dir;
}


