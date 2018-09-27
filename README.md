# How to run cluster
## For KONG app
* Define password for db in kong/secret.yml
* For the first start its need to do db migration, it can be done by editing value file in section `run_migration:` to `true`
* After first start change `run_migration:` value back to `false`
* Next step is import config to `kong` app, utility to do this with instruction is can be found in `kongak` folder

## For all db's
* Need to define password in value file `env_db` section or in secret 
