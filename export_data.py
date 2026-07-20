import boto3
import json
from datetime import datetime, timedelta

# Clients AWS
ec2 = boto3.client('ec2', region_name='eu-north-1')
rds = boto3.client('rds', region_name='eu-north-1')
s3 = boto3.client('s3', region_name='eu-north-1')
config = boto3.client('config', region_name='eu-north-1')
cloudtrail = boto3.client('cloudtrail', region_name='eu-north-1')
autoscaling = boto3.client('autoscaling', region_name='eu-north-1')

def save_json(data, filename):
    with open(f'exports/{filename}', 'w') as f:
        json.dump(data, f, indent=2, default=str)
    print(f"✅ Sauvegardé : exports/{filename}")

# 1. Instances EC2
instances = ec2.describe_instances()
save_json(instances, 'ec2_instances.json')

# 2. Security Groups
sgs = ec2.describe_security_groups()
save_json(sgs, 'security_groups.json')

# 3. VPC et sous-réseaux
vpcs = ec2.describe_vpcs()
subnets = ec2.describe_subnets()
save_json(vpcs, 'vpcs.json')
save_json(subnets, 'subnets.json')

# 4. RDS
db_instances = rds.describe_db_instances()
save_json(db_instances, 'rds_instances.json')

# 5. S3 buckets
buckets = s3.list_buckets()
save_json(buckets, 's3_buckets.json')

# 6. Règles AWS Config + conformité
config_rules = config.describe_config_rules()
save_json(config_rules, 'config_rules.json')

compliance = config.describe_compliance_by_config_rule()
save_json(compliance, 'config_compliance.json')

# 7. Auto Scaling
asg = autoscaling.describe_auto_scaling_groups()
save_json(asg, 'autoscaling_groups.json')

# 8. Logs CloudTrail (dernières 48h)
end_time = datetime.utcnow()
start_time = end_time - timedelta(hours=48)

events = cloudtrail.lookup_events(
    StartTime=start_time,
    EndTime=end_time,
    MaxResults=50
)
save_json(events, 'cloudtrail_events.json')

print("\n🎉 Export terminé ! Tous les fichiers sont dans exports/")
