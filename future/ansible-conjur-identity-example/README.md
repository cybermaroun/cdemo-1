# Using the Ansible Identity Role

This demo provides an example of how to use the `cyberark.conjur-host-identity` role to enroll a host and retrieve a secret from Conjur.

### Utilized Services
This demonstration uses the following containers:

* Conjur Master
* Conjur CLI
* Ansible Controller


### Running the Demo

Launch an unconfigured Conjur container using Docker Compose
```sh
$ ./0_start.sh
```

In a new tab:
```sh
$ ./1_run.sh
```
The above:
1. Configures the Conjur master with the admin password `secret` and the account `demo`
2. Loads a policy, which includes a layer and host factory.  The layer has read access to the variable `ansible/staging/foo/database/password` with the value: `super-secret_p@ssw0rd`
3. Generates a short term Host Factory Token
4. Installs the `cyberark.conjur-host-identity` onto a container with Ansible installed.
5. Runs the `conjur-identity-example.yml` playbook, using the generated Host Factory token to auto-enroll the Ansible container into the `ansible` layer.
6. Uses Summon to retrieve the secret value stored in Conjur
