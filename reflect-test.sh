#!/bin/bash
REQUEST_BODY="
{
  \"parallelism\": 1,
  \"overrides\": {
    \"hostnames\": [{
      \"original\": \"bceb58f5-8788-4205-829f-4313a89fac6b.cidemo.co\",
      \"replacement\": \"$EXPOSE_WEBSITE_URL\"
    }]
  }
}"

EXECUTION_ID=$(curl --location --silent --show-error --request POST 'https://api.reflect.run/v1/tags/layerci/executions' \
    --header "X-API-KEY: $REFLECT_API_KEY" \
    --header 'Content-Type: application/json' \
    --data-raw "$REQUEST_BODY" | jq -r '.executionId'
    )

echo "Running the tests... Execution id: $EXECUTION_ID"

STILL_RUNNING_TESTS=true
while [ "$STILL_RUNNING_TESTS" = "true" ]; do
    EXECUTION_STATUS=$( \
         curl --location --silent --show-error --request GET "https://api.reflect.run/v1/executions/$EXECUTION_ID" \
              --header "X-API-KEY: $REFLECT_API_KEY" \
              --header 'Content-Type: application/json' \
         )
    
    TESTS_FAILED=$(echo $EXECUTION_STATUS | jq -c '.tests[] | select(.status | contains("failed"))')
    STILL_RUNNING_TESTS=$(echo $EXECUTION_STATUS | jq -c '.tests[] | select(.status | contains("running") or contains("queued")) | length > 0')
    if ! [[ -z "$TESTS_FAILED" ]]; then
       printf "\e[1;31mSome tests has failed.\nReflect Execution ID: $EXECUTION_ID\nFailed tests: $TESTS_FAILED\n\n" >&2
       exit 1
    fi
    sleep 1
done

echo "All tests have completed"
