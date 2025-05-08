#!/bin/sh

#  refresh_settings_bundle_acknowledgements.sh
#  Simple ID Photo
#
#  Created by TakashiUshikoshi on 2023/03/27.
#  


if [[ $CI = "TRUE" ]]; then
    cd $CI_WORKSPACE

    `brew --prefix licenseplist`/bin/license-plist --output-path $CI_PRODUCT_PLATFORM/Settings.bundle --prefix Acknowledgements

    exit 0
fi

cd "$SRCROOT"

if [[ $TARGET_NAME = "Simple ID Photo (iOS)" ]]; then
    `brew --prefix licenseplist`/bin/license-plist --output-path iOS/Settings.bundle --prefix Acknowledgements
fi
