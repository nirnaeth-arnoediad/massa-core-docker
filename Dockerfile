# Download custom base
FROM ubuntu:20.04
 
# LABEL about the custom image
LABEL maintainer="benoit@alphatux.fr"
LABEL version="0.8.3"
LABEL description="Node Massa"
 
# Defini le timezone du container
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/Paris"

# Met a jour la liste des paquets
RUN apt-get update \
&& apt-get upgrade -y \
&& apt install -y pkg-config curl git build-essential libssl-dev screen procps \
&& apt autoclean -y

# Prepare l'environnement
#USER massa
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN source $HOME/.cargo/env \
&& rustup toolchain install nightly \
&& rustup default nightly

RUN git clone --branch testnet https://github.com/massalabs/massa.git

WORKDIR $HOME/massa/massa-node
RUN source $HOME/.cargo/env \
&& RUST_BACKTRACE=full cargo run --release |& tee logs.txt | if grep -q "Start bootstrapping from"; then pkill massa ; fi

WORKDIR $HOME/massa/massa-client
RUN source $HOME/.cargo/env \
&& cargo run --release

COPY ./massa-guard.sh /
COPY ./massa-guard_bootstrap_finder.py /
RUN chmod +x /massa-guard.sh \
&& chmod +x /massa-guard_bootstrap_finder.py \
&& mkdir /massa_mount

#Ouuverture des ports
EXPOSE 31244
EXPOSE 31245

# Lancement du node
CMD source $HOME/.cargo/env \
&& cd /massa/massa-client \
&& screen -dmS massa-client bash -c 'cargo run --release' \
&& sleep 1 \
&& cd /massa/massa-node \
&& screen -dmS massa-node bash -c 'RUST_BACKTRACE=full cargo run --release |& tee logs.txt' \
&& /massa-guard.sh \
&& /bin/bash