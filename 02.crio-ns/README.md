OS=Ubuntu_22.04
VERSION=1.28

sudo apt update
sudo apt install -y curl gnupg2 software-properties-common

# Aggiungi repository
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt update
sudo apt install -y cri-o cri-o-runc

# Abilita e avvia
sudo systemctl enable crio --now
