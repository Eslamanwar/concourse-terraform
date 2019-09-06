.phony: run-source destroy-source validate-source

source_dir=./

tf_destroy=terraform destroy --auto-approve
tf_apply=terraform apply --auto-approve
tf_validate=terraform validate
tf_init=terraform init

validate-source:
	cd ${source_dir} && ${tf_init} && ${tf_validate}

run-source:
	cd ${source_dir} && ${tf_init}
	cd ${source_dir} && ${tf_apply}

destroy-source:
	cd ${source_dir} && ${tf_init} && ${tf_destroy}

