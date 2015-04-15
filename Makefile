LEADS_QUERY_ENGINE_CONTAINER_NAME=query_engine
_HOW_MANY_UPLOAD_IN_PARALLEL=3
_VIRT_ENV_NAME=leads_query_engine
TARGET_UCLOUD=


dev_virtualenv_create:
	bash -c ". $$(which virtualenvwrapper.sh); mkvirtualenv $(_VIRT_ENV_NAME);"

dev_virtualenv_install_packages:
	bash -c ". $$(which virtualenvwrapper.sh) ; \
	workon $(_VIRT_ENV_NAME) ; \
	pip install -U -r requirements.txt ;" \
	echo "Use: workon $(_VIRT_ENV_NAME)" ;

dev_virtualenv_printname:
	@echo workon $(_VIRT_ENV_NAME)

deploy_saltstack_generate_config:
	python tools/salt/prepare_provider_conf.py

deploy_import_leads_deploy_ssh_key:
	nova keypair-add --pub_key ~/.ssh/leads_cluster.pub leads_cluster || nova keypair-list

deploy_create_salt_security_group:
	nova secgroup-create global_saltstack "allow nodes managed with salstack to communicate" && nova secgroup-add-rule global_saltstack tcp 4505 4506 0.0.0.0/0

# hadoop - 9000 and 9001 and 50070 (NameNode) and 8088 (resourcemanager)
deploy_create_yarn_security_group:
	nova secgroup-create internal_yarn "allow YARN nodes to communicate";\
	nova secgroup-add-group-rule internal_yarn internal_yarn tcp 9000 9000 ;\
	nova secgroup-add-group-rule internal_yarn internal_yarn tcp 9001 9001 ;\
	nova secgroup-add-group-rule internal_yarn internal_yarn tcp 50070 50070 ;\
	nova secgroup-add-group-rule internal_yarn internal_yarn tcp 8088 8088 ;

deploy_create_ispn_security_group:
	nova secgroup-create internal_ispn "allow ISPN nodes to communicate";\
	nova secgroup-add-group-rule internal_ispn internal_ispn tcp 54200 54200 ;\
	nova secgroup-add-group-rule internal_ispn internal_ispn tcp 55200 55200 ; \
	nova secgroup-add-group-rule internal_ispn internal_ispn tcp 11222 11222 ;

list_ucloud:
	sudo  salt-cloud -c salt --list-providers

list_images: 
	sudo  salt-cloud -c salt --list-sizes $(TARGET_UCLOUD)

generate_ssh_config:
	bash  tools/salt/generate_ssh_config.sh

test_vagrant_create_local_node:
	vagrant up

test_vagrant_install_openstck_cli:
	vagrant ssh -c "mkdir -p ~/tools"; \
	vagrant ssh -c "set +x; cd ~/tools; virtualenv openstack_cli; \
	source openstack_cli/bin/activate;\
	pip install -r /vagrant_tools/openstack_cli/requirements.txt"


upload_zips_to_container:
	vagrant ssh -c "source ~/tools/openstack_cli/bin/activate; \
	cd zips;\
	find * -name '*.zip' -type f | xargs -I {} -P $(_HOW_MANY_UPLOAD_IN_PARALLEL) \
	  swift \
	    --os-auth-url=$${OS_AUTH_URL} \
	    --os-username=$${OS_USERNAME} \
	    --os-password=$${OS_PASSWORD} \
	    --os-tenant-name=$${OS_TENANT_NAME} \
	    upload --skip-identical --changed $(LEADS_QUERY_ENGINE_CONTAINER_NAME) {}"


list_container:
	vagrant ssh -c " source ~/tools/openstack_cli/bin/activate; \
	swift \
	    --os-auth-url=$${OS_AUTH_URL} \
	    --os-username=$${OS_USERNAME} \
	    --os-password=$${OS_PASSWORD} \
	    --os-tenant-name=$${OS_TENANT_NAME} \
	    list  $(LEADS_QUERY_ENGINE_CONTAINER_NAME)"

# unicrawl archive
TARGET_SWIFT_OBJECT_SWIFT=/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/unicrawl/nutch.tgz
# infinispan archive
TARGET_SWIFT_OBJECT_ISPN=/v1/AUTH_73e8d4d1688f4e1f86926d4cb897091f/infinispan/infinispan-server-7.0.1-SNAPSHOT-NEW.tgz

TARGET_SWIFT_ENDPOINT=https://object-hamm5.cloudandheat.com:8080

# default value 30 days
TARGET_SWIFT_VALIDITY_OF_TEMPURL_SEC=24*60*60*30

get_swift_tempurl_unicrawl_archive: 
	$(MAKE) get_swift_tempurl TARGET_SWIFT_OBJECT=$(TARGET_SWIFT_OBJECT_SWIFT)

get_swift_tempurl:
	if test '$(SWIFT_TEMPURL_KEY)' = ""; then echo "SWIFT_TEMPURL_KEY must be set"; exit 1; fi; \
	unset OS_TENANT_ID ; \
	swift post -m "Temp-URL-Key: $(SWIFT_TEMPURL_KEY)" ; \
	swift  \
	tempurl GET $$(echo '$(TARGET_SWIFT_VALIDITY_OF_TEMPURL_SEC)' | bc) $(TARGET_SWIFT_OBJECT)  $(SWIFT_TEMPURL_KEY) | xargs -I {} echo $(TARGET_SWIFT_ENDPOINT){}

get_swift_tempurl_ispn_archive:
	$(MAKE) get_swift_tempurl TARGET_SWIFT_OBJECT=$(TARGET_SWIFT_OBJECT_ISPN)




