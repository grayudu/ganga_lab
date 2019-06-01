import json
import boto3
autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')

# Update auto scaling group max size
def update_auto_scaling_group_max_size( autoscaling_group_name, max_size ):
    response = autoscaling.update_auto_scaling_group(
        AutoScalingGroupName=autoscaling_group_name,
        MinSize=max_size,
        DesiredCapacity=max_size,
        MaxSize=5
    )
    if response['ResponseMetadata']['HTTPStatusCode'] == 200:
        return True
    else:
        print("ERROR: Unable to set max autoscaling group size on '" + autoscaling_group_name + "'")
    return False

def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    print(message['NewStateValue'])
    paginator = autoscaling.get_paginator('describe_auto_scaling_groups')
    groups = paginator.paginate(PaginationConfig={'PageSize': 100})
    #print groups
    filtered_asgs = groups.search('AutoScalingGroups[] | [?contains(Tags[?Key==`{}`].Value, `{}`)]'.format('Project', 'gangaapp'))
    for asg in filtered_asgs:
        asg_name = asg['AutoScalingGroupName']
    print(asg_name)
    if message['NewStateValue'] == 'OK':
        update_auto_scaling_group_max_size(asg_name, 1)
    if message['NewStateValue'] == 'ALARM':
        update_auto_scaling_group_max_size(asg_name, 3)
