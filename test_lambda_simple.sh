#!/bin/bash
# Simple Lambda test with test handler

echo "Testing Lambda with diagnostic handler..."
echo '{"test":"simple"}' > /tmp/simple_payload.json

aws lambda invoke \
  --function-name geojson-data-processor \
  --cli-binary-format raw-in-base64-out \
  --payload file:///tmp/simple_payload.json \
  /tmp/test_response.json

echo ""
echo "Response:"
cat /tmp/test_response.json

echo ""
echo ""
echo "Waiting 5 seconds, then checking logs..."
sleep 5

aws logs tail "/aws/lambda/geojson-data-processor" --since 1m --format short

