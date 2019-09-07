# concourse terraform

## usage

### specifying the version

the tasks require a pipeline to provide them with their docker image resource

this ensures you provide a specific version of the terraform image when executing

```yaml
resources:
# the terraform tasks
- name: concourse-terraform
  type: git
  source:
    uri: https://github.com/Snapkitchen/concourse-terraform

# the terraform image
- name: concourse-terraform-image
  type: docker-image
  source:
    repository: snapkitchen/concourse-terraform
    tag: {VERSION}

jobs:
# a job using a terraform task with the terraform image
- name: terraform-task
  plan:
  - get: concourse-terraform
  - get: concourse-terraform-image
  - task: do-terraform-task
    image: concourse-terraform-image
    file: concourse-terraform/tasks/{TASK}.yml
```

you can also build the docker image yourself using the [docker-image-resource](https://github.com/concourse/docker-image-resource) and the `Dockerfile` from the source

### providing input variable values

tfvars can be provided by:

- including `terraform.tfvars` or `*.auto.tfvars` files in the `TF_WORKING_DIR`

- passing them as parameters into the task

	```yaml
	jobs:
	# a terraform task with variables
	- name: terraform-task
	  plan:
	  - get: concourse-terraform
	  - get: concourse-terraform-image
	  - task: do-terraform-task
	    image: concourse-terraform-image
	    file: concourse-terraform/tasks/{TASK}.yml
	    params:
	      TF_VAR_my_var: my_value
	```

- converting a terraform output file into an input var file

	to provide a terraform output file, set the environment variable `TF_OUTPUT_VAR_FILE_{name}` to the path of the terraform output file

	- the file `{name}.tfvars.json` will be created in the `TF_WORKING_DIR` directory

	- the path to `{name}.tfvars.json` will be provided to `-var-file`

	- if the terraform output file only contains a single value, you must set `{name}` to the terraform input var you are setting

		example, to set the `cluster_region` terraform input var:

		given terraform output `cluster/region.json` from `TF_OUTPUT_TARGET_region`

		```
		{
		  "sensitive": false,
		  "type": "string",
		  "value": "us-east-1"
		}
		```

		and env var

		```
		TF_OUTPUT_VAR_FILE_cluster_region="cluster/region.json"
		```

		results in `{TF_WORKING_DIR}/cluster_region.tfvars.json`

		```
		{
		  "cluster_region": "us-east-1"
		}
		```

	- if the terraform output file contains multiple values, `{name}` is only used for the file name, in which case the terraform output name must already match the intended terraform input var names

	  example, attempting to set `cluster_region` and `cluster_name` terraform input vars:

		given terraform output `cluster/tf-output.json`

		```
		{
		  "cluster_region": {
		    "sensitive": false,
		    "type": "string",
		    "value": "us-east-1"
		  },
		  "cluster_name": {
		    "sensitive": true,
		    "type": "string",
		    "value": "foo"
		  }
		}
		```

		and env var

		```
		TF_OUTPUT_VAR_FILE_cluster="cluster/tf-output.json"
		```

		results in `{TF_WORKING_DIR}/cluster.tfvars.json`

		```
		{
		  "cluster_region": "us-east-1",
		  "cluster_name": "foo"
		}
		```

### configuring the backend

the backend can be configured two ways:

- by including a `.tf` file containing the backend configuration in the `TF_DIR_PATH`

- by specifying the `TF_BACKEND_TYPE` parameter to automatically create a `backend.tf` file for you

the backend configuration can be dynamically provided with additional params in the form of `TF_BACKEND_CONFIG_{var_name}: {var_value}`

e.g. to automatically create and configure an s3 backend:

```yaml
jobs:
# a terraform task with variables
- name: terraform-task
  plan:
  - get: concourse-terraform
  - get: concourse-terraform-image
  - task: do-terraform-task
    image: concourse-terraform-image
    file: concourse-terraform/tasks/{TASK}.yml
    params:
      TF_BACKEND_TYPE: s3
      TF_BACKEND_CONFIG_bucket: my-bucket
      TF_BACKEND_CONFIG_key: path/to/my/key
      TF_BACKEND_CONFIG_region: us-east-1
```

results in `backend.tf`:

```hcl
terraform {
  backend "s3" {}
}
```

with init parameters:

```sh
terraform init \
  -backend-config="bucket=my-bucket" \
  -backend-config="key=path/to/my/key" \
  -backend-config="region=us-east-1"
```

### providing terraform source files

terraform source files are provided through the `terraform-source-dir` input and the `TF_WORKING_DIR` and `TF_DIR_PATH` parameters

by default, the `TF_WORKING_DIR` is used as both the working directory and the target for terraform, meaning terraform expects that all `.tf` files are contained in this directory

there are two ways to specify the terraform directory:

1. set `TF_WORKING_DIR` to the `terraform` dir path

	e.g. a resource `src` with the source tree containing:
	
	```
	src/terraform/terraform.tf
	```
	
	might configure the following task:
	
	```yaml
	- task: terraform-plan
	  image: concourse-terraform-image
	  file: concourse-terraform/tasks/plan.yaml
	  input_mapping:
	    terraform-source-dir: src
	  params:
	    TF_WORKING_DIR: terraform-source-dir/terraform
	```

	the advantage to the this method is that only the contents of the `src/terraform` are copied to the working directory. this may reduce the size of the plan artifact if you have a lot of extra files in your source tree.

2. set the `TF_DIR_PATH` to the `terraform` dir path relative to `TF_WORKING_DIR`

	e.g. a resource `src` with a source tree containing:
	
	```
	src/
	src/templates/example.tpl
	src/terraform/terraform.tf
	```

	with a terraform template that references a source tree path:
	
	```hcl
	data "template_file" "example" {
	  template = "${file("templates/example.tpl")}"
	}
	```
	
	might configure the following task:
	
	```yaml
	- task: terraform-plan
	  image: concourse-terraform-image
	  file: concourse-terraform/tasks/plan.yaml
	  input_mapping:
	    terraform-source-dir: src
	  params:
	    TF_DIR_PATH: terraform
	```

	the advantage to this method is that you can reference additional relative files outside of the terraform directory.

	this path would become invalid if the `TF_WORKING_DIR` was set to `terraform-source-dir/terraform`, since the working directory tree would contain
	
	```
	terraform.tf
	```

	where `templates/example.tpl` does not exist

	in that case setting `TF_DIR_PATH` to target the terraform dir inside the `TF_WORKING_DIR` would result in the working directory tree:

	```
	templates/example.tpl
	terraform/terraform.tf
	```
	
	with `terraform` being the target terraform directory

# Design
![alt text](https://github.com/Eslamanwar/concourse-terraform/blob/master/concourse.jpg?raw=true)
