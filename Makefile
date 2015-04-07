LEADS_QUERY_ENGINE_CONTAINER_NAME=query_engine
_HOW_MANY_UPLOAD_IN_PARALLEL=3
_VIRT_ENV_NAME=leads_query_engine


dev_virtualenv_create:
	bash -c ". $$(which virtualenvwrapper.sh); mkvirtualenv $(_VIRT_ENV_NAME);"

dev_virtualenv_install_packages:
	bash -c ". $$(which virtualenvwrapper.sh) ; \
	workon $(_VIRT_ENV_NAME) ; \
	pip install -U -r requirements.txt ;" \
	echo "Use: workon $(_VIRT_ENV_NAME)" ;

dev_virtualenv_printname:
	@echo workon $(_VIRT_ENV_NAME)

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



