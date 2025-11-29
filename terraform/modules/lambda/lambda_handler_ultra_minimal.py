def lambda_handler(event, context):
    print("ULTRA MINIMAL: Lambda executed!")
    return {"statusCode": 200, "body": "OK"}

