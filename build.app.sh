#!/bin/bash

# Configuration - Update these paths to match your system
export SDK_PATH="$HOME/android-sdk"
export BUILD_TOOLS_VER="33.0.0" # Example version
export PLATFORM_VER="33"
export BUILD_TOOLS="$SDK_PATH/build-tools/$BUILD_TOOLS_VER"
export PLATFORM="$SDK_PATH/platforms/android-$PLATFORM_VER/android.jar"

# Project Structure
PACKAGE_NAME="com.example.minimal"
PACKAGE_PATH="com/example/minimal"
OUT_DIR="out"
GEN_DIR="gen"
OBJ_DIR="obj"

# Utility for error handling
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error in function: $1"
        echo "Reason: $2"
        # exit 1
        return 1
    fi
}

build_init() {
    echo "Executing: build_init"
    rm -rf $OUT_DIR $GEN_DIR $OBJ_DIR
    mkdir -p $GEN_DIR/$PACKAGE_PATH $OBJ_DIR $OUT_DIR
    check_status "build_init" "Failed to create directory structure"
}

compiling_resources() {
    echo "Executing: compiling_resources"
    # Generate R.java and package resources
    $BUILD_TOOLS/aapt package -f -m \
        -J $GEN_DIR \
        -M AndroidManifest.xml \
        -S res \
        -I $PLATFORM
    check_status "compiling_resources" "AAPT resource packaging failed"
}

compiling_java() {
    echo "Executing: compiling_java"
    # Compile Java source + R.java
    javac -d $OBJ_DIR \
        -classpath $PLATFORM \
        -source 1.8 -target 1.8 \
        src/$PACKAGE_PATH/*.java $GEN_DIR/$PACKAGE_PATH/*.java
    check_status "compiling_java" "Java compilation failed"
}

packaging_dex() {
    echo "Executing: packaging_dex"
    # Convert bytecode to Android Dex format
    $BUILD_TOOLS/dx --dex --output=$OUT_DIR/classes.dex $OBJ_DIR
    check_status "packaging_dex" "DEX conversion failed"
}

packaging_dex_d8() {
    echo "Executing: packaging_dex_d8"
    # D8 handles class to dex conversion
    # --lib points to the android.jar for symbol resolution
    $BUILD_TOOLS/d8 \
        --release \
        --lib "$PLATFORM" \
        --output "$OUT_DIR/" \
        $OBJ_DIR/$PACKAGE_PATH/*.class
    check_status "packaging_dex_d8" "D8 DEX conversion failed."
}

create_apk() {
    echo "Executing: create_apk"
    # Create the initial unaligned APK
    $BUILD_TOOLS/aapt package -f \
        -M AndroidManifest.xml \
        -S res \
        -I $PLATFORM \
        -F $OUT_DIR/minimal.unsigned.apk \
        $OUT_DIR
    check_status "create_apk" "Final APK packaging failed"
}

create_key() {
    echo "Executing: creating_key"
    # Generate a debug keystore if it doesn't exist
    if [ ! -f my-release-key.jks ]; then
        keytool -genkey -v -keystore my-release-key.jks \
            -keyalg RSA -keysize 2048 -validity 10000 \
            -alias my-alias -storepass password -keypass password \
            -dname "CN=Minimal, OU=Dev, O=Example, L=City, S=State, C=US"
        check_status "creating_key" "Keytool generation failed"
    fi
}

signing_apk() {
    echo "Executing: signing_apk"
    # Sign the APK using apksigner
    $BUILD_TOOLS/apksigner sign --ks my-release-key.jks \
        --ks-pass pass:password \
        --out $OUT_DIR/minimal.signed.apk \
        $OUT_DIR/minimal.unsigned.apk
    check_status "signing_apk" "APK signing failed"
}


install_nodemon() {
    echo "Executing: install_nodemon"
    # Check if npm is installed, then install nodemon globally
    if ! command -v nodemon &> /dev/null; then
        sudo npm install -g nodemon
        check_status "install_nodemon" "Failed to install nodemon via npm."
    fi
}

generate_nodemon_config() {
    echo "Executing: generate_nodemon_config"

  # Change it if needed
  # "exec": "./build_script.sh"

    cat <<EOF > nodemon.json
{
  "verbose": true,
  "ignore": ["out/*", "obj/*", "gen/*"],
  "watch": ["src/", "res/", "AndroidManifest.xml"],
  "ext": "java,xml,jks",
  "exec": "source build.app.sh && android_minimal_build nokey"
}
EOF
    check_status "generate_nodemon_config" "Could not write nodemon.json"
}


transfer_file () {
  source_file=$1
  target_dir=${2:-storage/self/primary/Download/}
  adb push $source_file $target_dir;
}

start_watch_mode() {
    echo "Executing: start_watch_mode"
    echo "Starting nodemon to watch Android files..."
    nodemon
    check_status "start_watch_mode" "Nodemon failed to start."
}

verify_device() {
    echo "Executing: verify_device"
    # Check if any device or emulator is connected
    DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device" | wc -l)
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        check_status "verify_device" "No Android device or emulator detected. Please start your AVD."
    fi
}


## Install offline
install_transfered_apk () {
  # Only use this if the file is ALREADY inside the Android filesystem
  echo "Executing: install_transfered_apk"
  # adb shell pm install -r "/storage/emulated/0/Download/minimal.signed.apk"
  adb shell pm install -r "/storage/self/primary/Download/minimal.signed.apk"
}

install_apk() {
    echo "Executing: install_apk"
    if [[ -n $1 ]]; then
      APK_PATH=$1
    fi

    # -r: Reinstall (replaces existing app while keeping data)
    # -t: Allow test packages
    # -g: Grant all runtime permissions automatically
    adb install -r -t -g "$APK_PATH"
    check_status "install_apk" "Failed to install APK to device: $APK_PATH"
}

launch_app() {
    echo "Executing: launch_app"
    # Format: adb shell am start -n package.name/package.name.ActivityName
    adb shell am start -n com.example.minimal/com.example.minimal.MainActivity
    check_status "launch_app" "Failed to start the Activity."
}


android_minimal_build () {
  should_create_key=${1:-"with_key"}

  # --- Execution Flow ---
  build_init
  compiling_resources
  sleep .2;
  compiling_java
  # packaging_dex
  sleep .2;
  packaging_dex_d8
  sleep .2;
  create_apk

  if [[ $should_create_key -eq "with_key" ]]; then
    create_key
  fi

  signing_apk

  sleep .2;

  # transfer_file out/minimal.signed.apk

  install_apk ./out/minimal.signed.apk && \
    launch_app 

  echo "--------------------------------------"
  echo "Build Successful: $OUT_DIR/minimal.signed.apk"
}


echo ${#@}
if [[ ${#@} -gt 0 ]]; then
  echo "watch: ";

  if [[ $1 -eq "watch" ]]; then
    echo "watch: ";
    echo "android_minimal_build : ";
    android_minimal_build nokey;
  fi
fi


