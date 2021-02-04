.PHONY: clean terraform-archive terraform-projector

CMD ?= plan

TERRAFORM_MODULE_PATHS := micronaut-oci-hol-free-tier-account/terraform
OCI_REGION := us-ashburn-1
OS_NS := cloudnative-devrel
OS_BC := micronaut-hol

define create_zip
	echo "Creating archive from $1"
	zip -r -j $(basename $1).zip $1 -x \*hcl \*tfstate\* \*provider\*
endef

define upload_zip
	echo "Uploading zip archive $1 as $(basename $2)"
	oci os object put -ns ${OS_NS} -bn ${OS_BC} --file $1 --name $2 --region ${OCI_REGION}
endef

terraform-projector:
	terraform -chdir=micronaut-oci-hol-free-tier-account/terraform/jidea-image $(CMD)

terraform-archive: clean
	echo "Creating terraform archives"
	$(foreach TDIR, $(wildcard $(TERRAFORM_MODULE_PATHS)/*), $(call create_zip, $(TDIR)))

terraform-projector-upload: terraform-archive
	$(call upload_zip, micronaut-oci-hol-free-tier-account/terraform/jidea-image.zip, terraform/jidea-image.zip)

clean:
	find micronaut-oci-hol-free-tier-account/terraform -type f -name "*.zip" -exec rm -rf {} \;