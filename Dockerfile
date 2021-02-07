# Select base image.
ARG fedorav
FROM fedora:${fedorav}
# Takes app name from directory container Dockerfile.
ARG app

ARG usezsh
# Take username details from host
ARG user
# Base packages to be installed by apt.
ARG packages

# Install packages and configure container
RUN dnf update -y && \
    dnf install -y $packages && \
    useradd $user -G wheel && \
    sed -i 's/%wheel.*/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

#####################################################
# Developer Tools - Comment to disable in container #
#####################################################
# Automation #
##############
# Terraform | Define Terraform version and install Terraform
ARG terraformv
RUN if [ ! "${terraformv}" == "disabled" ]; then dnf install -y dnf-plugins-core && dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo && dnf install -y ${terraformv}; fi

# Packer | Define Packer version and install Packer
ARG packerv
RUN if [ ! "${packerv}" == "disabled" ]; then dnf install -y dnf-plugins-core && dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo && dnf install -y ${packerv}; fi

# Ansible | Latest
ARG ansiblev
RUN if [ ! "${ansiblev}" == "disabled" ]; then dnf install -y ${ansiblev}; fi

#######################
# Shell configuration #
#######################
# Install zsh and oh-my-zsh and set init user
USER $user
RUN if [ "$usezsh" == "true" ]; then sudo dnf install -y zsh util-linux-user; sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; echo 'eval $(ssh-agent)' >> /home/$user/.zshrc; curl https://raw.githubusercontent.com/Rorasaurus/swann-container-zsh-theme/main/swann-container.zsh-theme > ~/.oh-my-zsh/themes/swann-container.zsh-theme; sed -i 's/ZSH_THEME=.*/ZSH_THEME="swann-container"/' ~/.zshrc; sudo chsh -s /bin/zsh $user; else echo 'eval $(ssh-agent)' >> /home/$user/.bashrc; fi

###############
# Cloud CLI's #
###############
# AWS CLI | Latest
USER root
ARG awscliv
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Configure working directory based upon Dockerfile directory name.
WORKDIR /home/$user/$app

# AWS Credentials
ARG container_secrets
ARG aws_secrets_file
ENV AWS_SHARED_CREDENTIALS_FILE=${container_secrets}/${aws_secrets_file}

# Set container entrypoint
USER $user
ARG entry
ENV entryenv=$entry
ENTRYPOINT "$entryenv"