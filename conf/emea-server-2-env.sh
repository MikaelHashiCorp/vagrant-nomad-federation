export NOMAD_ADDR=http://192.168.56.72:4646

grep -e "complete -C /usr/bin/nomad nomad" ~/.bashrc > /dev/null || nomad -autocomplete-install

grep -e "complete -C /usr/bin/consul consul" ~/.bashrc > /dev/null || consul -autocomplete-install

# Made with Bob
