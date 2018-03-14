#!/bin/bash -ex

docker-compose exec conjur-master \
  evoke configure master -h conjur-master -p secret demo

docker cp cdemo_conjur-master:/opt/conjur/etc/ssl/ca.pem ../certs/
openssl x509 -in ../certs/ca.pem -inform PEM -out ../certs/ca.crt

api_key=$(docker-compose exec conjur-master sudo -u conjur conjur-plugin-service possum rails r "print Credentials['demo:user:admin'].api_key" | tail -1)

echo '--------- Load Conjur Policy ------------'
output=$(docker-compose run --rm -e CONJUR_AUTHN_API_KEY=$api_key --entrypoint /bin/bash conjur-cli -c "
  cp /src/certs/ca.crt /usr/local/share/ca-certificates/ca.crt
  update-ca-certificates

  conjur policy load --replace root /src/policies/ansible.yml
  conjur list
  conjur variable values add ansible/staging/foo/database/password \"super-secret_p@ssw0rd\"

  conjur hostfactory tokens create --duration-days 3 ansible | jq -r '.[0].token'
")

hf_token=$(echo "$output" | tail -1 | tr -d '\r')

echo '--------- Run Ansible ------------'

docker-compose build ansible

docker-compose run --rm  ansible bash -c "
  ansible-galaxy install cyberark.conjur-host-identity
  HFTOKEN=$hf_token ansible-playbook -i \"localhost,\" -c local /src/playbooks/conjur-identity-example.yml
"

# summon --yaml 'SSH_KEY: !var:file ansible/staging/foo/ssh_private_key' bash -c 'ansible-playbook --private-key $SSH_KEY playbook/applications/foo.yml'
