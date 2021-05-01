#!/bin/bash

set -e

# print currently configured user to aid with debugging
cloudsmith whoami

publishToCloudsmith() {
  TYPE="$1"
  DISTRO="$2"
  VERSION="$3"
  PACKAGES=$4
  for i in $PACKAGES; do
    PACKAGE=${i##*/}
    # we can't upload both armv6 and armv7, so use armv7
    if [[ "$PACKAGE" == *"armv6"* ]]; then
      echo "Skipping $PACKAGE"
      continue
    fi

    echo "Uploading $PACKAGE"
    # attempt each publish up to 3 times
    cloudsmith push "$TYPE" "doppler/cli/$DISTRO/$VERSION" "dist/$PACKAGE" || \
      cloudsmith push "$TYPE" "doppler/cli/$DISTRO/$VERSION" "dist/$PACKAGE" || \
      cloudsmith push "$TYPE" "doppler/cli/$DISTRO/$VERSION" "dist/$PACKAGE"
  done;
}

# publish deb packages to cloudsmith
PACKAGES=$(find dist/*.deb  -type f)
publishToCloudsmith deb any-distro any-version "$PACKAGES"

# publish rpm packages to cloudsmith
PACKAGES=$(find dist/*.rpm  -type f)
publishToCloudsmith rpm any-distro any-version "$PACKAGES"

# publish alpine packages to cloudsmith
PACKAGES=$(find dist/*.apk  -type f)
publishToCloudsmith alpine alpine any-version "$PACKAGES"

# send Slack notification
MESSAGE="Doppler CLI $CLI_VERSION has been released."
curl --tlsv1.2 --proto "=https" -s -X "POST" "$SLACK_WEBHOOK_URL" -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8' \
  --data-urlencode "payload={\"username\": \"CLI Release Bot\", \"text\": \"$MESSAGE\"}"
