# to build, for exemple, run: 
# `username=mine groupname=ours docker run -d -i`
FROM ubuntu:latest AS dbp_skinny
ARG username=${username:-dev0}
ARG groupname=${groupname:-dev}

# set up basic utils
RUN apt-get update -yq && \
  apt-get upgrade -y && \
  # install github, build-essentials, libssl, etc
  apt-get install -y git gh build-essential libssl-dev ca-certificates wget curl gnupg lsb-release python3 python3-pip

# # set up group/user 
# RUN addgroup --system --gid 1000 ${groupname} && \
#     adduser --system --home /home/${username} --shell /bin/bash --uid 1000 --gid 1000 --disabled-password ${username}  
# set up groups
RUN addgroup --gid 1001 ${groupname} && \
  addgroup --gid 1008 devbp

RUN adduser --home /home/${username} --shell /bin/bash --uid 1000 --disabled-password ${username}
# make default user 
RUN echo -e "[user]\ndefault=${username}" >> /etc/wsl.conf

USER ${username}:devbp
# install cdir - an absolute lifesaver for speedy nav in an interactive cli (cannot be root for install)
RUN pip3 install cdir --user && \
  echo "alias cdir='source cdir.sh'" >> ~/.bashrc

# copy cdir install and copy current contents in /home/${username} to new user
# update all the paths (with etc/skel)
RUN export PATH=~/.local/bin:$PATH
USER root
RUN cp -r ./home/${username}/.local/bin /usr/local
RUN cp -r ./home/${username} /etc/skel

# add host user
RUN adduser --system --home /home/host --shell /bin/bash --disabled-password host
RUN usermod -aG sudo host
RUN usermod -aG sudo ${username}
# RUN adduser --system --home /home/host --shell /bin/bash --disabled-password host
# RUN sed -e 's;^# \(%sudo.*NOPASSWD.*\);\1;g' -i /etc/sudoers

# RUN usermod -aG sudo host
# RUN usermod -aG sudo ${username}

# all non-root users will need to use sudo from now on
RUN apt-get -y install sudo && \
  # add host and ${username} to sudo group
  sudo adduser ${username} sudo && \
  sudo adduser host sudo

# ensure no password and sudo runs as root
RUN passwd -d ${username} && passwd -d host && passwd -d root && passwd -l root
USER ${username}
WORKDIR /home/${username}

FROM dbp_skinny AS dbp_phat-dockerless
USER root
# for brave install - https://linuxhint.com/install-brave-browser-ubuntu22-04/
RUN curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://brave-browser-apt-release.s3.brave.com/ stable main"| tee /etc/apt/sources.list.d/brave-browser-release.list
# for docker install - https://docs.docker.com/engine/install/ubuntu/
RUN mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
# brave browser/gui/media/docker support
RUN apt-get update -yq && \
  apt-get install -y gedit gimp nautilus vlc x11-apps apt-transport-https brave-browser
USER ${username}

# TODO: https://github.com/mbacchi/brave-docker

FROM dbp_phat-dockerless as dbp_phat
USER root
# DOCKER
RUN apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
# GNOME
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install gnome-session gdm3
# CUDA
RUN apt-get -y install nvidia-cuda-toolkit
# VSCODE
RUN apt-get -y install software-properties-common apt-transport-https wget -y
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add -
RUN add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/vscode stable main"
RUN sudo apt-get -y install code
RUN apt-get -y update

USER ${username}




# username=dev08 groupname=whee docker compose -f docker-compose.ubuntu.yaml build
# username=dev08 groupname=wheel docker compose -f docker-compose.alpine.yaml build