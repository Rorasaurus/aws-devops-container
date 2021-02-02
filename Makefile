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

# Configure Ansible
ifeq ($(ANSIBLE), latest)
ANSIBLEV = ansible
else
ANSIBLEV = $(ANSIBLE)
endif

# Configure AWSCLI
ifeq ($(AWSCLI), latest)
AWSCLIV = awscli-exe-linux-x86_64.zip
else
AWSCLIV = $(AWSCLI)
endif

build:
	@echo "Building with..."
	@echo "	Terraform       : $(TERRAFORM)"
	@echo "	Packer          : $(PACKER)"
	@echo "	Ansible         : $(ANSIBLEV)"
	@echo "	awscli          : $(AWSCLIV)"
	-@sleep 3
	@$(RUNTIME) build \
		--build-arg app=$(APP) \
		--build-arg user=$(USER) \
		--build-arg terraformv=$(TERRAFORM) \
		--build-arg packerv=$(PACKER) \
		--build-arg ansiblev=$(ANSIBLEV) \
		--build-arg awscliv=$(AWSCLI) \
		--build-arg packages=$(PACKAGES) \
		--build-arg usezsh=$(USE-ZSH) \
		--build-arg entry=$(ENTRY) \
		--build-arg container_secrets=$(CONTAINER_SECRETS_DIR) \
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