#!/bin/sh

#  ci_pre_xcodebuild.sh
#  Simple ID Photo
#
#  Created by TakashiUshikoshi on 2023/03/19.
#

if [ $CI_WORKFLOW = "iOS Internal TestFlight Deployment" ]; then

    XCCONFIG_FILE=Shared/EnvironmentValues/Debug/EnvironmentValues_Debug.xcconfig

    if [ ! -d `dirname $XCCONFIG_FILE` ]; then
    
        echo "EnvironmentValues directory does not exist, so now creating the directory."

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
    
    echo "Writing environment values into .xcconfig file is done."
fi
