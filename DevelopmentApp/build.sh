#!/bin/sh

reveal_archive_in_finder=true

project="DevelopmentApp.xcodeproj"
framework_name="CompositeOperations"
framework="${framework_name}.framework"
ios_scheme="${framework_name}-iOS"
osx_scheme="${framework_name}-OSX"

project_dir=${PROJECT_DIR:-.}
build_dir=${BUILD_DIR:-Build}
configuration=${CONFIGURATION:-Release}

ios_simulator_path="${build_dir}/${framework_name}/${configuration}-iphonesimulator"
ios_simulator_binary="${ios_simulator_path}/${framework}/${framework_name}"

ios_device_path="${build_dir}/${framework_name}/${configuration}-iphoneos"
ios_device_binary="${ios_device_path}/${framework}/${framework_name}"

ios_universal_path="${build_dir}/${framework_name}/${configuration}-iphoneuniversal"
ios_universal_framework=${ios_universal_path}/${framework}
ios_universal_binary="${ios_universal_path}/${framework}/${framework_name}"

osx_path="${build_dir}/${framework_name}/${configuration}-macosx"
osx_framework="${osx_path}/${framework}"

distribution_path="${project_dir}/../Frameworks"
distribution_path_ios="${distribution_path}/iOS"
distribution_path_osx="${distribution_path}/OSX"

echo "Project:       $project"
echo "Scheme iOS:    $ios_scheme"
echo "Scheme OSX:    $osx_scheme"

echo "Project dir:   $project_dir"
echo "Build dir:     $build_dir"
echo "Configuration: $configuration"
echo "Framework      $framework"

echo "iOS Simulator build path: $ios_simulator_path"
echo "iOS Device build path:    $ios_device_path"
echo "iOS Universal build path: $ios_universal_path"
echo "iOS Universal framework:  $ios_universal_framework"
echo "OSX build path:           $osx_path"
echo "OSX framework:            $osx_framework"

echo "Output folder:     $distribution_path"
echo "iOS output folder: $distribution_path_ios"
echo "OSX output folder: $distribution_path_osx"

# Clean Build folder

rm -rf "${build_dir}"
mkdir -p "${build_dir}"

# Build iOS Frameworks: iphonesimulator and iphoneos

xcodebuild -project ${project} \
           -scheme ${ios_scheme} \
           -sdk iphonesimulator \
           -configuration ${configuration} \
           CONFIGURATION_BUILD_DIR=${ios_simulator_path} \
           clean build 

xcodebuild -project ${project} \
           -scheme ${ios_scheme} \
           -sdk iphoneos \
           -configuration ${configuration} \
           CONFIGURATION_BUILD_DIR=${ios_device_path} \
           clean build

# Create directory for universal framework

rm -rf "${ios_universal_path}"
mkdir "${ios_universal_path}"

mkdir -p "${ios_universal_framework}"

# Copy files Framework

cp -r "${ios_device_path}/." "${ios_universal_framework}"

# Make an universal binary

lipo "${ios_simulator_binary}" "${ios_device_binary}" -create -output "${ios_universal_binary}" | echo

# Codesign iOS universal framework

### FIXME

# Build OSX framework

xcodebuild -project ${project} \
           -scheme ${osx_scheme} \
           -sdk macosx \
           -configuration ${configuration} \
           CONFIGURATION_BUILD_DIR=${osx_path} \
           clean build 

# Copy results to output Frameworks/{iOS,OSX} directories

rm -rf "$distribution_path"
mkdir -p "$distribution_path_ios"
mkdir -p "$distribution_path_osx"

cp -av "${ios_universal_framework}" "${distribution_path_ios}"
cp -av "${osx_framework}" "${distribution_path_osx}"

# See results

if [ ${reveal_archive_in_finder} = true ]; then
    open "${distribution_path}"
fi

