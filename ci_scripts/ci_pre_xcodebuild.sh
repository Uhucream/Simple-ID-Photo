#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Simple ID Photo
#
#  Created by TakashiUshikoshi on 2023/03/19.
#

if [[ $CI_XCODE_SCHEME = "[Debug] Simple ID Photo (iOS)" ]]; then
    XCCONFIG_FILE="${CI_WORKSPACE}/Shared/EnvironmentVariables/Debug/EnvironmentVariables_Debug.xcconfig"
fi

if [[ $CI_XCODE_SCHEME = "[Release] Simple ID Photo (iOS)" ]]; then
    XCCONFIG_FILE="${CI_WORKSPACE}/Shared/EnvironmentVariables/Release/EnvironmentVariables_Release.xcconfig"
fi

echo .xcconfig file path is ${XCCONFIG_FILE}

if [ ! -d `dirname $XCCONFIG_FILE` ]; then

    echo "EnvironmentVariables directory does not exist, so now creating the directory."

    mkdir -p `dirname $XCCONFIG_FILE`
    
    echo "Creating directory is done."

fi

if [ ! -f $XCCONFIG_FILE ]; then

    echo ".xcconfig file does not exist, so now creating the file."

    touch $XCCONFIG_FILE
    
    echo "Creating file is done."

fi

echo "Now writing environment values into .xcconfig file."

echo "GAD_LIST_CELL_AD_UNIT_ID = ${GAD_LIST_CELL_AD_UNIT_ID}" >> $XCCONFIG_FILE
echo "GAD_APPLICATION_IDENTIFIER = ${GAD_APPLICATION_IDENTIFIER}" >> $XCCONFIG_FILE
echo "GAD_SHOULD_SHOW_AD_VALIDATOR = ${GAD_SHOULD_SHOW_AD_VALIDATOR}" >> $XCCONFIG_FILE

echo "IN_APP_PURCHASE_HIDE_ADS_PRODUCT_IDENTIFIER = ${IN_APP_PURCHASE_HIDE_ADS_PRODUCT_IDENTIFIER}" >> $XCCONFIG_FILE
echo "IN_APP_PURCHASE_BEER_PRODUCT_IDENTIFIER = ${IN_APP_PURCHASE_BEER_PRODUCT_IDENTIFIER}" >> $XCCONFIG_FILE
echo "IN_APP_PURCHASE_GYOZA_PRODUCT_IDENTIFIER = ${IN_APP_PURCHASE_GYOZA_PRODUCT_IDENTIFIER}" >> $XCCONFIG_FILE
echo "IN_APP_PURCHASE_RAMEN_PRODUCT_IDENTIFIER = ${IN_APP_PURCHASE_RAMEN_PRODUCT_IDENTIFIER}" >> $XCCONFIG_FILE

echo "Writing environment values into .xcconfig file is done."
