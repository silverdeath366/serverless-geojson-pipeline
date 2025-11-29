#!/bin/bash
# Test Lambda manual invoke

echo "Testing Lambda manual invoke..."

# Create payload
echo '{"test":"manual"}' > /tmp/payload.json

# Invoke Lambda
aws lambda invoke \
  --function-name geojson-data-processor \
  --cli-binary-format raw-in-base64-out \
  --payload file:///tmp/payload.json \
  /tmp/response.json

echo ""
echo "Response:"
cat /tmp/response.json

echo ""
echo ""
echo "Waiting 10 seconds, then checking logs..."
sleep 10

aws logs describe-log-streams \
  --log-group-name '/aws/lambda/geojson-data-processor' \
  --max-items 10 \
  --order-by LastEventTime \
  --descending

echo ""
echo "Recent logs:"
aws logs tail '/aws/lambda/geojson-data-processor' --since 2m --format short

