LEADS_QUERY_ENGINE_CONTAINER_NAME=query_engine
TENANT_NAME=

create_local_node:
	vagrant up


install_openstck_cli:
	vagrant ssh -c "mkdir -p ~/tools"; \
	vagrant ssh -c "set +x; cd ~/tools; virtualenv openstack_cli; \
	source openstack_cli/bin/activate;\
	pip install -r /vagrant_tools/openstack_cli/requirements.txt"


upload_zips_to_container:
	vagrant ssh -c "source ~/tools/openstack_cli/bin/activate; \
	swift --os-auth-url=$${OS_AUTH_URL} \
	--os-username=$${OS_USERNAME} --os-password=$${OS_PASSWORD} --os-tenant-name=$${OS_TENANT_NAME} list"

