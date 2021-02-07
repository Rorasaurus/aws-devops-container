include config

# Container variables
CURR_DIR:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
APP_DIR:=$(realpath $(CURR_PATH)../)
APP:=$(notdir $(APP_DIR))
IMAGE = "$(APP)-env-img"
CONTAINER = "$(APP)-env"
USER = $(shell whoami)

# Configure shell
ifeq ($(USE-ZSH), true)
ENTRY = "/bin/zsh"
else
ENTRY = "/bin/bash"
endif

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
USER_HOME := "/home/$(USER)"
endif
ifeq ($(UNAME_S),Darwin)
USER_HOME := "/Users/$(USER)"
endif

# Configure container
ifeq ($(DOCKER), true)
RUNTIME = "docker"
else ifeq ($(DOCKER), false)
RUNTIME = "podman"
endif

# Configure Terraform
ifeq ($(TERRAFORM), latest)
TERRAFORMV = terraform
else ifeq ($(TERRAFORM), disabled)
TERRAFORMV = disabled
else
TERRAFORMV = "terraform-$(TERRAFORM).x86_64"
endif

# Configure Packer
ifeq ($(PACKER), latest)
PACKERV = packer
else ifeq ($(PACKER), disabled)
PACKERV = disabled
else
PACKERV = "packer-$(PACKER).x86_64"
endif

# Configure Ansible
ifeq ($(ANSIBLE), latest)
ANSIBLEV = ansible
else ifeq ($(ANSIBLE), disabled)
ANSIBLEV = disabled
else
ANSIBLEV = "ansible-$(ANSIBLE).fc$(FEDORA).noarch"
endif

# Configure AWSCLI
ifeq ($(AWSCLI), latest)
AWSCLIV = awscli-exe-linux-x86_64.zip
else
AWSCLIV = $(AWSCLI)
endif

build:
	@echo "Building with..."
	@echo "Fedora			: $(FEDORA)"
	@echo "Terraform       	: $(TERRAFORM)"
	@echo "Packer          	: $(PACKER)"
	@echo "Ansible         	: $(ANSIBLE)"
	-@sleep 3
	@$(RUNTIME) build \
		--build-arg fedorav=$(FEDORA) \
		--build-arg app=$(APP) \
		--build-arg user=$(USER) \
		--build-arg terraformv=$(TERRAFORMV) \
		--build-arg packerv=$(PACKERV) \
		--build-arg ansiblev=$(ANSIBLEV) \
		--build-arg awscliv=$(AWSCLI) \
		--build-arg packages=$(PACKAGES) \
		--build-arg usezsh=$(USE-ZSH) \
		--build-arg entry=$(ENTRY) \
		--build-arg container_secrets=$(CONTAINER_SECRETS_DIR) \
		--build-arg aws_secrets_file=$(AWS_SECRETS_FILE) \
		-t $(IMAGE) .
	@$(RUNTIME) run --init -it --name $(CONTAINER) --hostname=$(CONTAINER) \
		-e "TERM=xterm-256color" \
		--volume $(APP_DIR):/home/$(USER)/$(APP):Z \
		--volume $(HOST_SECRETS_DIR):$(CONTAINER_SECRETS_DIR):Z \
		--volume $(HOST_SSH_DIR):$(CONTAINER_SSH_DIR):Z \
		--userns=keep-id \
		$(IMAGE)

# Delete image and container
prune:
	-@$(RUNTIME) rm $(CONTAINER)
	-@$(RUNTIME) rmi $(IMAGE)

# Start existing container
start:
	@$(RUNTIME) start -ai $(CONTAINER)

print-vars:
	-@echo $(ENTRY)
	-@echo $(PACKAGES)