this task is based on open source docker images (https://github.com/ljfranklin/terraform-resource.git)

To run this concourse pipeline

please modify terraform_source  to relative path to terraform tf files
and Bucket name must be exist 


fly -t tutorial login -c http://concourse-basic-example-alb-592854376.eu-west-1.elb.amazonaws.com -u admin -p dolphins

fly -t tutorial sp -p simple-app -c task.yml -v storage_access_key=AKIASK2QH4XF62UX37ES -v storage_secret_key=AWBtgIFEgqX4YHTjNGBY6UYWXLFYZCsFqDJ20Kht -v environment_access_key=AKIASK2QH4XF62UX37ES -v environment_secret_key=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



