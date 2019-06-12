#!/bin/bash
set -e

#
# --- Export Environment Variables for other Steps:
# You can export Environment Variables for other Steps with
#  envman, which is automatically installed by `bitrise setup`.
# A very simple example:
# envman add --key EXAMPLE_STEP_OUTPUT --value 'the value you want to share'
# Envman can handle piped inputs, which is useful if the text you want to
# share is complex and you don't want to deal with proper bash escaping:
#  cat file_with_complex_input | envman add --KEY EXAMPLE_STEP_OUTPUT
# You can find more usage examples on envman's GitHub page
#  at: https://github.com/bitrise-io/envman

#
# --- Exit codes:
# The exit code of your Step is very important. If you return
#  with a 0 exit code `bitrise` will register your Step as "successful".
# Any non zero exit code will be registered as "failed" by `bitrise`.

echo $GIT_CLONE_COMMIT
echo $PR
echo $dir_name

git diff --name-status "$GIT_CLONE_COMMIT_HASH" "$GIT_CLONE_COMMIT_HASH"^

LIST=$(git diff --name-status "$GIT_CLONE_COMMIT_HASH" "$GIT_CLONE_COMMIT_HASH"^)
if [[ $LIST == *"$dir_name"* ]]; then
    echo "Files changed. Build should proceed."
    CHANGED=true
else
    echo "Files not changed, should be skipped"
    CHANGED=false
fi

if [ -z "$BITRISE_GIT_MESSAGE" ]
then
    echo "\$BITRISE_GIT_MESSAGE is empty - build is manual. Not skipping the build."
else
    echo "\$BITRISE_GIT_MESSAGE is NOT empty - build is triggered."
    if [ "$CHANGED" = false ];
    then
        echo "Cancelling build NOW!"
        curl -X POST "https://api.bitrise.io/v0.1/apps/$BITRISE_APP_SLUG/builds/$BITRISE_BUILD_SLUG/abort" -H "accept: application/json" -H "Authorization: $BITRISE_ACCESS_TOKEN" -H "Content-Type: application/json" -d "{ \"abort_reason\": \"Files not changed\", \"abort_with_success\": true, \"skip_notifications\": true}"
    fi
fi
exit 0