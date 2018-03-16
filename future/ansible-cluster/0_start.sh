#!/bin/bash -ex

docker-compose build ansible

docker-compose run --rm  ansible bash -c "
  ansible-galaxy install cyberark.conjur-host-identity
"
# ansible-playbook -vvv -i "localhost," -c local /src/playbooks/conjur.yml
