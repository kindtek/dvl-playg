# to build, for exemple, run: 
# `username=mine groupname=ours docker run -d -i`
FROM ubuntu:latest AS dbp_essential-cdir
ARG username
ARG groupname
RUN apt-get update -yq && \
apt-get upgrade -y
# set up group/user 
RUN addgroup --system --gid 1000 ${groupname:-dev} && \
adduser --system --home /home/${username:-dev0} --shell /bin/bash --uid 1000 --gid 1000 --disabled-password ${username:-dev0}
# install build-essentials and sudo - from now on we will need to use sudo
RUN apt-get install -y build-essential sudo
# remove password
RUN sudo passwd -d ${username:-dev0}
# no pw so a sudo guardrail is nice
RUN sudo usermod -aG ${username:-dev0} 
# make default user
RUN sudo echo -e "[user]\ndefault=${username:-dev0}" >> /etc/wsl.conf

# biggest headache saver of all time - https://www.tecmint.com/cdir-navigate-folders-and-files-on-linux/
RUN sudo apt install -y python3 python3-pip && \
sudo pip3 install cdir


FROM dbp_essential-cdir AS dbp_git-cdir
RUN sudo apt-get update -y && \
apt-get install -y git gh
ENTRYPOINT [ echo "alias cdir='source cdir.sh'" >> ~/.bashrc && source ~/.bashrc ]

FROM dbp_git-cdir AS dbp_docker-git-cdir
# https://docs.docker.com/engine/install/ubuntu/
RUN sudo apt-get update -y &&  \
sudo apt-get install -y ca-certificates curl gnupg lsb-release
RUN sudo mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN sudo apt-get update
RUN sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin