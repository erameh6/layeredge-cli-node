# layeredge-cli-node
this is script to automats the installation process by automatically installing all dependencies and adding them to your path.


# how to install?

clone the repository : git clone https://github.com/bigray0x/layeredge-cli-node.git
enter the foldser : cd layeredge-cli-node
start the installarion : ./install_layeredge_node.sh

or use this to automate the process ⬇️

git clone https://github.com/bigray0x/layeredge-cli-node.git && cd layeredge-cli-node
./install_layeredge_node.sh

the script automatically installs all dependencies but but if it says Go not found use the command below to add go to your path and rerun the script using ./install_layeredge_node.sh

export PATH=$PATH:/usr/local/go/bin
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

if it doesn't break just input private key and let ir run, note that you won't see your private key when you paste it.

done. 