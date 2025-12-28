#!/bin/bash

# Configuration
PROJECT_NAME="MinimalAndroidApp"
PACKAGE_NAME="com.example.minimal"
PACKAGE_PATH="com/example/minimal"

create_structure() {
    echo "Executing: create_structure"
    mkdir -p "$PROJECT_NAME/src/$PACKAGE_PATH"
    mkdir -p "$PROJECT_NAME/res/layout"
    mkdir -p "$PROJECT_NAME/res/values"
    if [ $? -ne 0 ]; then echo "create_structure: Failed to create folders"; exit 1; fi
}

generate_manifest() {
    echo "Executing: generate_manifest"
    cat <<EOF > "$PROJECT_NAME/AndroidManifest.xml"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">
    <application android:label="MinimalApp">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
    if [ $? -ne 0 ]; then echo "generate_manifest: Failed to write XML"; exit 1; fi
}

generate_strings() {
    echo "Executing: generate_strings"
    cat <<EOF > "$PROJECT_NAME/res/values/strings.xml"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Minimal App</string>
    <string name="hello_msg">Hello from Terminal Build!</string>
</resources>
EOF
    if [ $? -ne 0 ]; then echo "generate_strings: Failed to write strings"; exit 1; fi
}

generate_layout() {
    echo "Executing: generate_layout"
    cat <<EOF > "$PROJECT_NAME/res/layout/activity_main.xml"
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/hello_msg"
        android:textSize="24sp" />
</LinearLayout>
EOF
    if [ $? -ne 0 ]; then echo "generate_layout: Failed to write layout"; exit 1; fi
}

generate_java() {
    echo "Executing: generate_java"
    cat <<EOF > "$PROJECT_NAME/src/$PACKAGE_PATH/MainActivity.java"
package $PACKAGE_NAME;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
EOF
    if [ $? -ne 0 ]; then echo "generate_java: Failed to write Java source"; exit 1; fi
}


create () {
  create_structure
  generate_manifest
  generate_strings
  generate_layout
  generate_java

  echo "-----------------------------------------------"
  echo "Project '$PROJECT_NAME' generated successfully."
}
