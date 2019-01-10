# How to run cluster
## For KONG app
* Define password for db in kong/secret.yml
* For the first start its need to do db migration, it can be done by editing value file in section `run_migration:` to `true`
* After first start change `run_migration:` value back to `false`
* Next step is import config to `kong` app, utility to do this with instruction is can be found in `kongak` folder

## For all db's
* Need to define password in value file `env_db` section or in secret

# INSTALL ALL CHARTS

1) Install `kubectl`, `kubedecode` and `helm`
    - Configure `kubectl` to connect the cluster
    - Do `helm init`

2) Create all namespaces and secrets for db
    - This can be implemented in two ways
        - You can create it manual
        - You can use script below  
```bash
### Create namespace's
NAMESPACES=(ael digital-signature em fe fraud il gndf kong logging man me mithril monitoring mpi ops prm redis replication reports traefik uaddresses verification)
for namespace in ${NAMESPACES[@]}; do
 kubectl create ns $namespace
done

### Create replication password
rep=$(openssl rand -hex 10);

### Create secrets
kubectl create secret generic db -n digital-signature --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n fraud --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n man --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n mithril --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n mpi --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n prm --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n reports --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n uaddresses --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n verification --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep;
kubectl create secret generic db -n em --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep
kubectl create secret generic db -n kong --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep

### Get secrets for db user
digital_signature=$(kubectl get secret --namespace digital-signature db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
fraud=$(kubectl get secret --namespace fraud db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
man=$(kubectl get secret --namespace man db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
mithril=$(kubectl get secret --namespace mithril db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
mpi=$(kubectl get secret --namespace mpi db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
prm=$(kubectl get secret --namespace prm db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
reports=$(kubectl get secret --namespace reports db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
uaddresses=$(kubectl get secret --namespace uaddresses db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
verification=$(kubectl get secret --namespace verification db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
em=$(kubectl get secret --namespace em db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);

### Create ops secrets
kubectl create secret generic db -n ops --from-literal=DB_PASSWORD=$(openssl rand -hex 10) --from-literal=REPLICATOR_PASSWORD=$rep --from-literal=DB_PASSWORD_BLOCK=$(openssl rand -hex 10) --from-literal=EM_PASSWORD=$em ;

ops=$(kubectl get secret --namespace ops db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
ops_block=$(kubectl get secret --namespace ops db -o jsonpath="{.data.DB_PASSWORD_BLOCK}" | base64 --decode ; echo);

### Create il secrets
kubectl create secret generic db -n il --from-literal=DB_PASSWORD=$(openssl rand -hex 10) \
--from-literal=REPLICATOR_PASSWORD=$rep \
--from-literal=PRM_PASSWORD=$prm \
--from-literal=BLOCKS_PASSWORD=$ops_block \
--from-literal=FRAUD_PASSWORD=$fraud  \
--from-literal=EM_PASSWORD=$em ;

il=$(kubectl get secret --namespace il db -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode ; echo);
```
3) Redis chart
    - deploy redis with -> `helm install -f redis/values.yaml --name redis redis --namespace redis`
    - get service name
        - `kubectl get svc -n redis`
    - Get `redis` password with `kubedecode redis redis`
        - `redis-password: ****`
4) Traefik chart
    - if use ssl, need to add certs in `"values_demo.yaml"` in the section  `ssl "defaultCert:"` and `"defaultKey:"` otherwise set `"ssl:  enabled: false"`
    - deploy traefik chart -> `helm install -f traefik-chart/values_demo.yaml --name traefik traefik-chart --namespace kube-system`

5) AEL chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
    - create all buckets that in `"KNOWN_BUCKETS"`
    - generate key in `json` for buckets, encode it to `base64` and add to `"template/gcs-secrets.yaml"` to `"sa.json:"` field
        - example ```{
 "type": "test_service_account",
 "project_id": "test",
 "private_key_id": "test",
 "private_key": "-----BEGIN RSA PRIVATE KEY-----\n
MIICWwIBAAKBgQCrFMN3ymnRjcd+eIfwtnY5VTRyDpLTl6DAKMtKhNfMq2SDyN54
DYkxJJ6SM2W7hKchO9uOYU6u25t9eOTfT3DYPcgXE+C5aWgmV/kNfHD+m3oe8d3m
Pju2XTTO+jYD3cI4+4LUSIZ0pbTWtkdBY//igwuDcevo/Tv6q6++6P24vQIDAQAB
AoGAAJWxlVc7xVuWsvf2fvwgq1F/PGSQW+jIw99f0oFhu3FahpjJKd/h+CkH4bgL
QPjTGWn69iGfAzn87hDbt2euGw2rfU9CMUUsGRsR9XpOXF3RoJ1p1iljHyzSYEUc
hxYIXRu9KuoVgGItzQEc8ITlP8i8/hCSIhyCxb3AHPO6KAECQQDjiGg+zj4ABOOf
wm63+/r+g9xExHH5R9usKYEZOXSpO8EUkr4soRXiMBZlRImOnd/l9qtIruGXHCAw
m8OnMLiRAkEAwHxHHsi8I0CoPdqQwBH1sYpWDt6C3uoRnPxXm4DntSdzNp9W9tlo
RZf4aje1vIE7xVY2X96I8tQjBqxSS/ZzbQJAZfs3rh7Gjz+hvnNpKLGaGAWF7pSV
+QMKJKodoO6tqUSND+mNr3cr1ctz3kPP28pLFklvEA7CMfZ7Pw4xrXga4QJASkir
+clmMgSl6RkMe9Nyik3k4GAnCXgzy+3msXCR+2t6Hz5nBWTpxNHdYMCXNmR5eLLI
0T7Eg1IzIkQmjoJSEQJAVgh91OTPnSkJLPa2+0eVz8PvD/4tP7q2J6hD3+OaJ8aH
j64DRPAcB081o3+PwHG38zp+6IhFsprhGL79zVEYJg==
-----END RSA PRIVATE KEY-----\n",
 "client_email": "test@test.com",
 "client_id": "test",
 "auth_uri": "https://test.com/o/oauth2/auth",
 "token_uri": "https://test.com/o/oauth2/token",
 "auth_provider_x509_cert_url": "https://test.com/oauth2/v1/certs",
 "client_x509_cert_url": "https://test.com"
}``` would be in base64 ```ewogICJ0eXBlIjogInRlc3Rfc2VydmljZV9hY2NvdW50IiwKICAicHJvamVjdF9pZCI6ICJ0ZXN0IiwKICAicHJpdmF0ZV9rZXlfaWQiOiAidGVzdCIsCiAgInByaXZhdGVfa2V5IjogIi0tLS0tQkVHSU4gUlNBIFBSSVZBVEUgS0VZLS0tLS0KTUlJQ1d3SUJBQUtCZ1FDckZNTjN5bW5SamNkK2VJZnd0blk1VlRSeURwTFRsNkRBS010S2hOZk1xMlNEeU41NApEWWt4Sko2U00yVzdoS2NoTzl1T1lVNnUyNXQ5ZU9UZlQzRFlQY2dYRStDNWFXZ21WL2tOZkhEK20zb2U4ZDNtClBqdTJYVFRPK2pZRDNjSTQrNExVU0laMHBiVFd0a2RCWS8vaWd3dURjZXZvL1R2NnE2Kys2UDI0dlFJREFRQUIKQW9HQUFKV3hsVmM3eFZ1V3N2ZjJmdndncTFGL1BHU1FXK2pJdzk5ZjBvRmh1M0ZhaHBqSktkL2grQ2tINGJnTApRUGpUR1duNjlpR2ZBem44N2hEYnQyZXVHdzJyZlU5Q01VVXNHUnNSOVhwT1hGM1JvSjFwMWlsakh5elNZRVVjCmh4WUlYUnU5S3VvVmdHSXR6UUVjOElUbFA4aTgvaENTSWh5Q3hiM0FIUE82S0FFQ1FRRGppR2cremo0QUJPT2YKd202MysvcitnOXhFeEhINVI5dXNLWUVaT1hTcE84RVVrcjRzb1JYaU1CWmxSSW1PbmQvbDlxdElydUdYSENBdwptOE9uTUxpUkFrRUF3SHhISHNpOEkwQ29QZHFRd0JIMXNZcFdEdDZDM3VvUm5QeFhtNERudFNkek5wOVc5dGxvClJaZjRhamUxdklFN3hWWTJYOTZJOHRRakJxeFNTL1p6YlFKQVpmczNyaDdHanoraHZuTnBLTEdhR0FXRjdwU1YKK1FNS0pLb2RvTzZ0cVVTTkQrbU5yM2NyMWN0ejNrUFAyOHBMRmtsdkVBN0NNZlo3UHc0eHJYZ2E0UUpBU2tpcgorY2xtTWdTbDZSa01lOU55aWszazRHQW5DWGd6eSszbXNYQ1IrMnQ2SHo1bkJXVHB4TkhkWU1DWE5tUjVlTExJCjBUN0VnMUl6SWtRbWpvSlNFUUpBVmdoOTFPVFBuU2tKTFBhMiswZVZ6OFB2RC80dFA3cTJKNmhEMytPYUo4YUgKajY0RFJQQWNCMDgxbzMrUHdIRzM4enArNkloRnNwcmhHTDc5elZFWUpnPT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS1cbiIsCiAgImNsaWVudF9lbWFpbCI6ICJ0ZXN0QHRlc3QuY29tIiwKICAiY2xpZW50X2lkIjogInRlc3QiLAogICJhdXRoX3VyaSI6ICJodHRwczovL3Rlc3QuY29tL28vb2F1dGgyL2F1dGgiLAogICJ0b2tlbl91cmkiOiAiaHR0cHM6Ly90ZXN0LmNvbS9vL29hdXRoMi90b2tlbiIsCiAgImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3Rlc3QuY29tL29hdXRoMi92MS9jZXJ0cyIsCiAgImNsaWVudF94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vdGVzdC5jb20iCn0=```
    - deploy ael with helm
        - `helm install -f ael/values-demo.yaml --name ael ael --namespace ael`

6) Kong chart
    - deploy `kong` chart
        - `helm install -f kong/values-demo.yaml --name kong kong --namespace kong`
    - wait while db pod will be in running state
    - edit `values-demo.yaml`:
        - set ```log_backups: 
             	 enabled: false/true``` __(log_backup save postgresql log to google bucket use it to other charts too)__
        - set `run_migration: true` and change in `templates/kong_migration_postgres.yaml` line `command: [ "/bin/sh", "-c", "kong migrations up" ]` to `command: [ "/bin/sh", "-c", "kong migrations bootstrap" ]` and upgrade `kong` with `helm`
            - `helm upgrade -f kong/values-demo.yaml kong kong`
        - set `run_migration: false` and upgrade `kong`
            - `helm upgrade -f kong/values-demo.yaml kong kong`
        - set `run_migration: true` and change in `templates/kong_migration_postgres.yaml` line `command: [ "/bin/sh", "-c", "kong migrations bootstrap" ]` to `command: [ "/bin/sh", "-c", "kong migrations up" ]` and upgrade `kong`
            - `helm upgrade -f kong/values-demo.yaml kong kong`
        - set `run_migration: false` and upgrade `kong` this step remove migration pod from cluster
            - `helm upgrade -f kong/values-demo.yaml kong kong`

7) Gndf chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
       - `API_CLIENTID: ""` is `username` like `admin`
       - `API_CLIENTSECRET: ""` is password `some_random_password`
    - deploy gndf
        - `helm install -f gndf/values.yaml --name gndf gndf --namespace gndf`

8) Digital-signature chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f digital-signature/values-demo.yaml --name digital-signature digital-signature --namespace digital-signature`
9) Event-manager chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f em/values-demo.yaml --name em em --namespace em`

10) Fraud chart
   - install chart with helm
       - `helm install -f fraud/values-demo.yaml --name fraud fraud --namespace fraud`

11) Report chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f report/values-demo.yaml --name reports report --namespace reports`

12) Uaddresses chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f uaddresses/values-demo.yaml --name uaddresses uaddresses --namespace uaddresses`

13) Verification chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f verification/values-demo.yaml --name verification verification --namespace verification`

14) Mithril chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
        - `JWT_SECRET: ""`
   - install chart with helm
       - `helm install -f mithril/values-demo.yaml --name mithril mithril --namespace mithril`

15) Man chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - need to fill `  AUTH_HOST: ""` with the `url` of `auth` endpoint `auth.exemple.com`
   - install chart with helm
       - `helm install -f man/values-demo.yaml --name man man --namespace man`

16) Mpi chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - need to create secret in mpi namespace with name `config-toml` and content ```[core."Core.Repo"]
database = "mpi"
username = "db"
password = "<db-password>"
hostname = "db-svc"
port = 5432```
        - kubectl create secret generic config-toml --from-env-file="config-toml"
   - install chart with helm
       - `helm install -f mpi/values-demo.yaml --name mpi mpi --namespace mpi`

17) Ops chart
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f ops/values-demo.yaml --name ops ops --namespace ops`

18) Prm chart
   - install chart with helm
       - `helm install -f prm/values-demo.yaml --name prm prm --namespace prm`

19) Il chart
    - copy `redis` secret to `il` namespace
        - `kubectl get secrets redis -n redis -o yaml | sed 's/namespace: redis/namespace: il/' | kubectl create -f -`
    - fill out `values.yaml`:
        - `HOST: "0.0.0.0"` - or some hostname
        - `SECRET: "<gen some value>"`
        - `ERLANG_COOKIE: "<gen some value>"`
   - install chart with helm
       - `helm install -f il/values-demo.yaml --name il il --namespace il`

20) Fe chart
    - For correct work it's must fill out all values with correct names of dns
   - install chart with helm
       - `helm install -f fe/values-demo.yaml --name fe fe --namespace fe`

21) For logical replication its need to manually add tables in provider and subscriber this all provided in `PGLOGICAL.md`
