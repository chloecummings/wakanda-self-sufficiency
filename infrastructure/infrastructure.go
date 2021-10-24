package main

import (
	"log"
	"os"

	"github.com/aws/aws-cdk-go/awscdk"
	"github.com/aws/aws-cdk-go/awscdk/awsec2"
	"github.com/aws/aws-cdk-go/awscdk/awsrds"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/constructs-go/constructs/v3"
	"github.com/aws/jsii-runtime-go"
	"github.com/joho/godotenv"
)

var wss = "wakandaSelfSufficiency"
var username = "wssAdmin"

type InfrastructureStackProps struct {
	awscdk.StackProps
}

func NewInfrastructureStack(scope constructs.Construct, id string, props *InfrastructureStackProps) awscdk.Stack {
	var sprops awscdk.StackProps
	if props != nil {
		sprops = props.StackProps
	}
	stack := awscdk.NewStack(scope, &id, &sprops)

	// Create VPC
	vpc := awsec2.NewVpc(stack, aws.String("wssVPC"), &awsec2.VpcProps{
		Cidr: aws.String("172.30.0.0/16"),
		SubnetConfiguration: &[]*awsec2.SubnetConfiguration{
			{
				Name:       aws.String("wssRDS"),
				CidrMask:   aws.Float64(24),
				SubnetType: awsec2.SubnetType_PUBLIC,
			},
		},
	})

	// Create Security Group
	securityGroup := awsec2.NewSecurityGroup(stack, aws.String("wssRDSSecurityGroup"), &awsec2.SecurityGroupProps{
		Vpc:               vpc,
		SecurityGroupName: aws.String("wss-rds"),
	})

	// Create Subnet Group
	subnetGroup := awsrds.NewSubnetGroup(stack, aws.String("wssSubnetGroup"), &awsrds.SubnetGroupProps{
		Vpc:         vpc,
		Description: aws.String("Subnet group for the Wakanda Self Sufficiency project"),
		VpcSubnets: &awsec2.SubnetSelection{
			SubnetType: awsec2.SubnetType_PUBLIC,
		},
	})

	// Create RDS Cluster
	awsrds.NewDatabaseCluster(stack, &wss, &awsrds.DatabaseClusterProps{
		Engine: awsrds.DatabaseClusterEngine_AuroraPostgres(&awsrds.AuroraPostgresClusterEngineProps{
			Version: awsrds.AuroraPostgresEngineVersion_VER_11_9(),
		}),
		ClusterIdentifier:   &wss,
		Credentials:         awsrds.Credentials_FromPassword(&username, awscdk.NewSecretValue(os.Getenv("DB_PASSWORD"), nil)),
		DefaultDatabaseName: &wss,
		IamAuthentication:   aws.Bool(true),
		StorageEncrypted:    aws.Bool(true),
		// StorageEncryptionKey: encryptionKey,
		InstanceProps: &awsrds.InstanceProps{
			Vpc:                       vpc,
			AllowMajorVersionUpgrade:  aws.Bool(true),
			AutoMinorVersionUpgrade:   aws.Bool(true),
			EnablePerformanceInsights: aws.Bool(true),
			// PerformanceInsightEncryptionKey: encryptionKey,
			PerformanceInsightRetention: awsrds.PerformanceInsightRetention_DEFAULT,
			InstanceType:                awsec2.InstanceType_Of(awsec2.InstanceClass_MEMORY5, awsec2.InstanceSize_LARGE),
			PubliclyAccessible:          aws.Bool(true),
			SecurityGroups: &[]awsec2.ISecurityGroup{
				securityGroup,
			},
			VpcSubnets: &awsec2.SubnetSelection{
				SubnetType: awsec2.SubnetType_PUBLIC,
			},
		},
		InstanceIdentifierBase: &wss,
		Instances:              aws.Float64(1),
		Port:                   aws.Float64(5432),
		SubnetGroup:            subnetGroup,
	})

	return stack
}

func main() {
	// get environment variables from local .env file
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatalf("Error loading .env file")
	}

	app := awscdk.NewApp(&awscdk.AppProps{})

	NewInfrastructureStack(app, "WSSInfrastructureStack", &InfrastructureStackProps{
		awscdk.StackProps{
			Env: env(),
		},
	})

	app.Synth(nil)
}

// env determines the AWS environment (account+region) in which our stack is to
// be deployed. For more information see: https://docs.aws.amazon.com/cdk/latest/guide/environments.html
func env() *awscdk.Environment {
	return &awscdk.Environment{
		Account: aws.String(os.Getenv("AWS_ACCOUNT_ID")),
		Region:  jsii.String("us-east-2"),
	}
}
