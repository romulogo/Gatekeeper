# Gatekeeper
cloud services firewall automatation

to start the project, configure the following variables in the `Dockerfile`.

- `firewall_type`: to inform cloud servers (DO to digital ocean or GC to Google Cloud).
- `loop_var`: to inform the waiting time (in minutes) each time the garekeeper updates the firewall.
- `ports`: to inform the port range that will be opened.

# Digital Ocean
- `acess_key`: the access token for the cloud service.
- `firewall_name`: the name of the firewall to be updated.

# Google Cloud
- `acess_key`: the project_id, it is contained in the json credentia.
- `firewall_name`: give your firewall a name to be created and updated by the Gatekeeper (WARNING: DO NOT CHANGE).
- remember to fill in `gc_authentication.json` with your json credentials

after registering the information. run in your terminal in the `GATEKEEPER-API` folder, just run `docker-compose run gatekeeper`.