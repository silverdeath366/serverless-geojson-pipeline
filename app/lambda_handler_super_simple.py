def lambda_handler(event, context):
    import sys
    print("SUPER SIMPLE HANDLER EXECUTED", file=sys.stderr)
    print("SUPER SIMPLE HANDLER EXECUTED", file=sys.stdout)
    return {"statusCode": 200}

