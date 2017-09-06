from troposphere import Parameter, Ref, Template, Tags, If, Equals, Not, Join
from troposphere.constants import KEY_PAIR_NAME, SUBNET_ID, M4_LARGE, NUMBER
import troposphere.emr as emr
import troposphere.iam as iam
import sys, os, re

scaling_policy = emr.SimpleScalingPolicyConfiguration(
          AdjustmentType="EXACT_CAPACITY",
          ScalingAdjustment="1",
          CoolDown="300"
        )
      
parameters = {
  "PrivateSubnet" : Parameter(
    "PrivateSubnet",
    Description = "The subnet to create the cluster in",
    Type = "AWS::EC2::Subnet::Id",
    Default = "subnet-54ab6922",
    ),
  "SpotPrice" : Parameter(
    "SpotPrice",
    Description = "Spot price (or use 0 for 'on demand' instance)",
    Type = "Number",
    Default = "0"
    ),    
  "KeyName" : Parameter(
    "KeyName",
    Description = "Name of the SSH Key",
    Type = "AWS::EC2::KeyPair::KeyName",
    Default = "mrgeo",
    ),
  "EMRRelease" : Parameter(
    "EMRRelease",
    Description = "EMR Release Version",
    Type = "String",
    Default = "emr-5.8.0",
    ),
  "EMRRole" : Parameter(
    "EMRRole",
    Description = "ARN of existing EMR Role",
    Type = "String",
    Default = "EMR_DefaultRole",
    ),
  "EMRInstanceProfile" : Parameter(
    "EMRInstanceProfile",
    Description = "ARN of existing EMR Instance Profile",
    Type = "String",
    Default = "EMR_EC2_DefaultRole",
    ),    
  "InstanceType" : Parameter(
    "InstanceType",
    Type="String",
    Description="EC2 instance type",
    Default="m4.large",
    AllowedValues=[
      "m1.medium", "m1.large", "m1.xlarge",
      "m4.large", "m4.xlarge",
      "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "c1.medium", "c1.xlarge",
    ],
    ConstraintDescription="Must be an EC2 instance type supported by EMR",
    ),      
}
#withSpotPrice = "WithSpotPrice"
#template.add_condition(withSpotPrice, Not(Equals(Ref(spot), "0")))


# Function to write template to specified file
def write_to_file( template ):
  
  # Define the directory to write to as located one level up from the current directory, in a folder named templates
  dir = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..','templates'))
  
  # Create the directory if it does not exist
  if not os.path.exists(dir):
    os.makedirs(dir)
  
  # Define filename for template equal to name of current script    
  filename = re.sub('\.py$','', sys.argv[0])
  file = os.path.join(dir,filename)
  
  # Write the template to file
  target = open(file + '.json', 'w')
  target.truncate()
  target.write(template)
  target.close()

# Generate Scaling Rules
def generate_scaling_rules(rules_name):
  global emr, scaling_policy

  rules = [
    emr.ScalingRule(
      Name=rules_name,
      Description="%s rules" % rules_name,
      Action=emr.ScalingAction(
        Market="ON_DEMAND",
        SimpleScalingPolicyConfiguration=scaling_policy
      ),
      Trigger=emr.ScalingTrigger(
        CloudWatchAlarmDefinition=emr.CloudWatchAlarmDefinition(
          ComparisonOperator="GREATER_THAN",
          EvaluationPeriods="120",
          MetricName="TestMetric",
          Namespace="AWS/ElasticMapReduce",
          Period="300",
          Statistic="AVERAGE",
          Threshold="50",
          Unit="PERCENT",
          Dimensions=[
            emr.MetricDimension(
              'my.custom.master.property',
              'my.custom.master.value'
            )
          ]
        )
      )
    )
  ]
  return rules
    
def gen_cluster( cluster_name ):
  cluster = emr.Cluster(
    cluster_name,
    Name=cluster_name,
    ReleaseLabel=Ref(parameters["EMRRelease"]),

    JobFlowRole=Ref(parameters["EMRInstanceProfile"]),
    ServiceRole=Ref(parameters["EMRRole"]),

    Instances=emr.JobFlowInstancesConfig(
      Ec2KeyName=Ref(parameters["KeyName"]),
      Ec2SubnetId=Ref(parameters["PrivateSubnet"]),
      MasterInstanceGroup=emr.InstanceGroupConfigProperty(
        Name="Master Instance",
        InstanceCount="1",
        InstanceType=Ref(parameters["InstanceType"]),
        Market="ON_DEMAND",
      ),
      CoreInstanceGroup=emr.InstanceGroupConfigProperty(
        Name="Core Instance",
  #      BidPrice=If(withSpotPrice, Ref(spot), Ref("AWS::NoValue")),
  #      Market=If(withSpotPrice, "SPOT", "ON_DEMAND"),
  #      AutoScalingPolicy=emr.AutoScalingPolicy(
  #        Constraints=emr.ScalingConstraints(
  #          MinCapacity="1",
  #          MaxCapacity="3"
  #        ),
  #        Rules=generate_rules("CoreAutoScalingPolicy"),
  #      ),
  #      EbsConfiguration=emr.EbsConfiguration(
  #        EbsBlockDeviceConfigs=[
  #          emr.EbsBlockDeviceConfigs(
  #            VolumeSpecification=emr.VolumeSpecification(
  #              SizeInGB="10",
  #              VolumeType="gp2"
  #            ),
  #            VolumesPerInstance="1"
  #          )
  #        ],
  #        EbsOptimized="true"
  #      ),
        InstanceCount="1",
        InstanceType=M4_LARGE,
      )
    ),
    Applications=[
      emr.Application(Name="Hadoop"),
      emr.Application(Name="Hive"),
      emr.Application(Name="Mahout"),
      emr.Application(Name="Pig"),
      emr.Application(Name="Spark")
    ],
    VisibleToAllUsers="true",
    Tags=Tags(
      Name=cluster_name
    )
  )
  return cluster
######################## MAIN BEGINS HERE ###############################
def main(argv):
  
  # Set up a blank template
  t = Template()
  
  # Add description
  t.add_description("Sample CloudFormation template for creating an EMR cluster")

  # Add all defined input parameters to template
  for p in parameters.values():
    t.add_parameter(p)
  
  t.add_resource(gen_cluster("EMRSampleCluster"))
  
  # Convert template to json
  template=(t.to_json())
  
  # Print template to console (for debugging) and write to file
  print(template)
  write_to_file(template)

if __name__ == "__main__":
  main(sys.argv[0:])