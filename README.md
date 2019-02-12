# How to run cluster

## Setup kubernetes

1) You can set up kubernetes in your environment using this instruction [kubernetes.io](https://kubernetes.io/docs/setup/)
2) You can use `Google Kubernetes Engine`, more information about you can find here [GKE](https://cloud.google.com/kubernetes-engine/)

## Install all charts

1) Install `kubectl`, `kubedecode` and `helm`
- Configure `kubectl` to connect the cluster
- `helm init`

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
- set redis password in `values.yaml` section `password` or if it's empty it would generate password
- deploy redis
  - `helm install -f redis/values.yaml --name redis redis --namespace redis`
- get service name
  - `kubectl get svc -n redis`
- get `redis` password with
  - `kubedecode redis redis`

4) Traefik chart
- if you use ssl, need to add certs in `"values_demo.yaml"` in the section  `ssl "defaultCert:"` and `"defaultKey:"` otherwise set `"ssl:  enabled: false"`
- deploy traefik chart 
  - `helm install -f traefik-chart/values_demo.yaml --name traefik traefik-chart --namespace kube-system`

5) AEL chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- create all buckets that in `"KNOWN_BUCKETS"`
  - generate key in `json` for buckets, encode it to `base64` and add to `"template/gcs-secrets.yaml"` to `"sa.json:"` field
  - example

```json
        {
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
}
```

__would be in base64__

```
ewogICJ0eXBlIjogInRlc3Rfc2VydmljZV9hY2NvdW50IiwKICAicHJvamVjdF9pZCI6ICJ0ZXN0IiwKICAicHJpdmF0ZV9rZXlfaWQiOiAidGVzdCIsCiAgInByaXZhdGVfa2V5IjogIi0tLS0tQkVHSU4gUlNBIFBSSVZBVEUgS0VZLS0tLS0KTUlJQ1d3SUJBQUtCZ1FDckZNTjN5bW5SamNkK2VJZnd0blk1VlRSeURwTFRsNkRBS010S2hOZk1xMlNEeU41NApEWWt4Sko2U00yVzdoS2NoTzl1T1lVNnUyNXQ5ZU9UZlQzRFlQY2dYRStDNWFXZ21WL2tOZkhEK20zb2U4ZDNtClBqdTJYVFRPK2pZRDNjSTQrNExVU0laMHBiVFd0a2RCWS8vaWd3dURjZXZvL1R2NnE2Kys2UDI0dlFJREFRQUIKQW9HQUFKV3hsVmM3eFZ1V3N2ZjJmdndncTFGL1BHU1FXK2pJdzk5ZjBvRmh1M0ZhaHBqSktkL2grQ2tINGJnTApRUGpUR1duNjlpR2ZBem44N2hEYnQyZXVHdzJyZlU5Q01VVXNHUnNSOVhwT1hGM1JvSjFwMWlsakh5elNZRVVjCmh4WUlYUnU5S3VvVmdHSXR6UUVjOElUbFA4aTgvaENTSWh5Q3hiM0FIUE82S0FFQ1FRRGppR2cremo0QUJPT2YKd202MysvcitnOXhFeEhINVI5dXNLWUVaT1hTcE84RVVrcjRzb1JYaU1CWmxSSW1PbmQvbDlxdElydUdYSENBdwptOE9uTUxpUkFrRUF3SHhISHNpOEkwQ29QZHFRd0JIMXNZcFdEdDZDM3VvUm5QeFhtNERudFNkek5wOVc5dGxvClJaZjRhamUxdklFN3hWWTJYOTZJOHRRakJxeFNTL1p6YlFKQVpmczNyaDdHanoraHZuTnBLTEdhR0FXRjdwU1YKK1FNS0pLb2RvTzZ0cVVTTkQrbU5yM2NyMWN0ejNrUFAyOHBMRmtsdkVBN0NNZlo3UHc0eHJYZ2E0UUpBU2tpcgorY2xtTWdTbDZSa01lOU55aWszazRHQW5DWGd6eSszbXNYQ1IrMnQ2SHo1bkJXVHB4TkhkWU1DWE5tUjVlTExJCjBUN0VnMUl6SWtRbWpvSlNFUUpBVmdoOTFPVFBuU2tKTFBhMiswZVZ6OFB2RC80dFA3cTJKNmhEMytPYUo4YUgKajY0RFJQQWNCMDgxbzMrUHdIRzM4enArNkloRnNwcmhHTDc5elZFWUpnPT0KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS1cbiIsCiAgImNsaWVudF9lbWFpbCI6ICJ0ZXN0QHRlc3QuY29tIiwKICAiY2xpZW50X2lkIjogInRlc3QiLAogICJhdXRoX3VyaSI6ICJodHRwczovL3Rlc3QuY29tL28vb2F1dGgyL2F1dGgiLAogICJ0b2tlbl91cmkiOiAiaHR0cHM6Ly90ZXN0LmNvbS9vL29hdXRoMi90b2tlbiIsCiAgImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3Rlc3QuY29tL29hdXRoMi92MS9jZXJ0cyIsCiAgImNsaWVudF94NTA5X2NlcnRfdXJsIjogImh0dHBzOi8vdGVzdC5jb20iCn0=
```
- deploy ael with helm
  - `helm install -f ael/values-demo.yaml --name ael ael --namespace ael`

6) Kong chart
- set in `tamplates/dep.yaml` value `replicas:` to `0` its need for migrations database
- deploy `kong` chart
  - `helm install -f kong/values-demo.yaml --name kong kong --namespace kong`
- wait while db pod will be in running state `1/1`
- edit `values-demo.yaml`: `log_backups: enabled: false/true `
- __(log_backup save postgresql log to google bucket use it to other charts too)__
- set `run_migration: true` and upgrade `kong` with `helm`
  - `helm upgrade -f kong/values-demo.yaml kong kong`
- set `run_migration: false` and upgrade `kong` this step remove migration pod from cluster
  - `helm upgrade -f kong/values-demo.yaml kong kong`
- scale api pods with
  - `kubectl scale deployment -n kong --replicas 1 api`
- fill out `redis` password in `kong-dev.yaml`
  - import config to `kong` app
    - utility to do this with instruction can be found in `kongak` folder

7) Digital-signature chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- install chart with helm
  - `helm install -f digital-signature/values-demo.yaml --name digital-signature digital-signature --namespace digital-signature`
- fill table `certs` in `digital-signature` db for correct work of the system

8) Event-manager chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- install chart with helm
  - `helm install -f em/values-demo.yaml --name em em --namespace em`

9) Fraud chart
- install chart with helm
  - `helm install -f fraud/values-demo.yaml --name fraud fraud --namespace fraud`

10) Report chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- install chart with helm
  - `helm install -f report/values-demo.yaml --name reports report --namespace reports`

11) Uaddresses chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
  - `CLIENT_ID:  ""`
  - `CLIENT_SECRET: ""`
  - `host: uaddresses.example.com`
  - `API_ENDPOINT: "http://api.example.com/api/uaddresses"`
  - `AUTH_ENDPOINT: "http://api.example.com"`
  - `OAUTH_REDIRECT_URL: "http://uaddresses.example.com/auth/redirect"`
  - `OAUTH_URL: "http://auth.example.com/sign-in"`
- install chart with helm
  - `helm install -f uaddresses/values-demo.yaml --name uaddresses uaddresses --namespace uaddresses`

12) Verification chart
- create or copy `redis` secret to `verification` namespace
  - `kubectl get secrets redis -n redis -o yaml | sed 's/namespace: redis/namespace: il/' | kubectl create -f -`
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- if you have api andpoint of ypur sms provider you can fill out those values
  - `GATEWAY_URL: ""`
  - `GATEWAY_LOGIN: ""`
  - `GATEWAY_PASSWORD: ""`
  - `GATEWAY_STATUS_URL: ""`
- install chart with helm
  - `helm install -f verification/values-demo.yaml --name verification verification --namespace verification`

13) Mithril chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
  - `JWT_SECRET: "<gen some value>"`
  - `CLIENT_ID:  ""`
  - `CLIENT_SECRET: ""`
  - `OAUTH_REDIRECT_URL: "http://mithril.example.com/auth/redirect"`
  - `API_ENDPOINT: "http://api.example.com"`
  - `OAUTH_URL: "http://auth.example.com/sign-in"`
  - `host: mithril.example.com`
- install chart with helm
  - `helm install -f mithril/values-demo.yaml --name mithril mithril --namespace mithril`

14) Man chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- need to fill `  AUTH_HOST: ""` with the `url` of `auth` endpoint `auth.exemple.com`
  - `AUTH_HOST: "http://auth.example.com"`
- install chart with helm
  - `helm install -f man/values-demo.yaml --name man man --namespace man`

15) Mpi chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- need to create secret in mpi namespace with name `config-toml` and content:
    ```yaml
    [core."Core.Repo"]
    database = "mpi"
    username = "db"
    password = "__db-password__"
    hostname = "db-svc"
    port = 5432
    ```
*Note that `__db-password__` is autogenerated password in k8s secret in the first paragraph.
- `kubectl create secret generic config-toml --from-env-file="config-toml"`
- install chart with helm
  - `helm install -f mpi/values-demo.yaml --name mpi mpi --namespace mpi`

16) Ops chart
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- install chart with helm
  - `helm install -f ops/values-demo.yaml --name ops ops --namespace ops`

17) Prm chart
- install chart with helm
  - `helm install -f prm/values-demo.yaml --name prm prm --namespace prm`

18) Il chart
- create or copy `redis` secret to `il` namespace
  - `kubectl get secrets redis -n redis -o yaml | sed 's/namespace: redis/namespace: il/' | kubectl create -f -`
- fill out `values.yaml`:
  - `HOST: "0.0.0.0"` - or some hostname
  - `SECRET: "<gen some value>"`
  - `ERLANG_COOKIE: "<gen some value>"`
- for the e-mails to work correctly, the following values ​​must be filled
  - `POSTMARK_ENDPOINT: ""`
  - `POSTMARK_API_KEY: ""`
  - `MAILGUN_API_KEY: ""`
  - `MAILGUN_DOMAIN: ""`
  - `BAMBOO_SMTP_SERVER: ""`
  - `BAMBOO_SMTP_HOSTNAME: ""`
  - `BAMBOO_SMTP_PORT: 587`
  - `BAMBOO_SMTP_USERNAME: ""`
  - `BAMBOO_SMTP_PASSWORD: ""`
  - `BAMBOO_EMPLOYEE_REQUEST_INVITATION_FROM: ""` <- email from which to send letters
  - `BAMBOO_EMPLOYEE_REQUEST_UPDATE_INVITATION_FROM: ""` <- email from which to send letters
  - `BAMBOO_EMPLOYEE_CREATED_NOTIFICATION_FROM: ""` <- email from which to send letters
  - `BAMBOO_CREDENTIALS_RECOVERY_REQUEST_INVITATION_FROM: ""` <- email from which to send letters
  - `EMAIL_VERIFICATION_TEMPLATE_ID: ""` <- this value can be found in `man` database, need to insert `id` of the value with `title` `Email verification`
  - `EMAIL_VERIFICATION_FROM: ""` <- email from which to send letters
  - `CHAIN_VERIFICATION_FAILED_NOTIFICATION_FROM: ""` <- email from which to send letters
  - `CHAIN_VERIFICATION_FAILED_NOTIFICATION_TO: ""` <- email to send letters
  - `CHAIN_VERIFICATION_FAILED_NOTIFICATION_SUBJECT: ""` <- email subject
  - `CIPHER_KEYPHRASE: "<gen some value>"`
  - `CIPHER_IVPHRASE: "<gen some value>"`
  - `JWT_SECRET: "<gen some value>"`
- for simplifying testing of system recommended to set `DIGITAL_SIGNATURE_ENABLED: "false"`
- install chart with helm
  - `helm install -f il/values-demo.yaml --name il il --namespace il`

19) Fe chart
- For correct work it's must fill out all values with correct names of dns
  - `## FE ADMIN ##` section
    - `REACT_APP_API_URL: ""` <- url to `api` endpoint
    - `REACT_APP_CLIENT_ID: ""` <- need to create in `mithril`
    - `REACT_APP_CLIENT_SECRET: ""` <- need to create in `mithril`
    - `REACT_APP_OAUTH_URL: ""` <- url to `<auth_url>/sign-in` endpoint
    - `REACT_APP_OAUTH_REDIRECT_URI: ""` <- url to `<admin_url>/auth/redirect` endpoint
    - `REACT_APP_SIGNER_URL: ""` <- url to `<auth_url>/auth/redirect` endpoint
  - `## FE ADMIN GATEKEEPER ##` section
    - `OAUTH_REDIRECT_URI: ""` <- url to `<admin_url>/auth/redirect` endpoint
    - `REACT_APP_CLIENT_ID: ""` <- need to create in `mithril`, must be the same as in `## FE ADMIN ##` section
    - `REACT_APP_CLIENT_SECRET: ""` <- need to create in `mithril`, must be the same as in `## FE ADMIN ##` section
    - `COOKIE_DOMAIN: ""` <- root domain, for example, you have admin panel in domain `admin.staging.example.com` so your cookie-domain will be `.staging.example.com`
  - `## FE ADMIN LEGACY ##` section
    - `REACT_APP_API_HOST:  ""` <- url to `api` endpoint
    - `REACT_APP_CLIENT_ID: ""` <- need to create in `mithril`
    - `REACT_APP_OAUTH_URL: ""` <- url to `<auth_url>/sign-in` endpoint
    - `REACT_APP_OAUTH_REDIRECT_URI: ""` <- url to `<admin_url>/auth/redirect` endpoint
    - `REACT_APP_SIGNER_URL: ""` <- url to `<auth_url>/auth/redirect` endpoint
    - `REACT_APP_APP_ENV: ""` <- value for multiple environment for example can be `dev/demo/preprod/prod`
    - `REACT_APP_BI_URL: ""` <- if you have business intelligence service like PowerBI you can paste link here to your dashboard
  - `## FE ADMIN LEGACY GATEKEEPER ##` section
    - `OAUTH_REDIRECT_URI: ""` <- url to `<admin_url>/auth/redirect` endpoint
    - `CLIENT_ID: ""` <- need to create in `mithril`, must be the same as in `## FE ADMIN ##` section
    - `CLIENT_SECRET: ""` <- need to create in `mithril`, must be the same as in `## FE ADMIN ##` section
    - `COOKIE_DOMAIN: ""`<- root domain, for example, you have admin panel in domain `admin.staging.example.com` so your cookie-domain will be `.staging.example.com`
  - `## FE PORTAL ##` section
    - `loadBalancerIP: ` <- if you have loadbalancer ypu can fill this value with the ip adress
    - `API_ENDPOINT: ""` <- url to `api` endpoint
  - `## FE AUTH ##` section
    - `loadBalancerIP: ` <- if you have loadbalancer ypu can fill this value with the ip adress
    - `REACT_APP_API_URL: ""` <- url to `api` endpoint
    - `REACT_APP_AUTH_URL: ""` <- url to `api` endpoint
    - `REACT_APP_PROXY_URL: ""` <- url to `proxy` endpoint for example `proxy.demo.example.com`
    - `REACT_APP_CLIENT_ID: ""` <- need to create in `mithril`, must be the same as in `## FE ADMIN ##` section
    - `REACT_APP_PATIENT_ACCOUNT_REDIRECT_URI: ""` <- url to account endpoint `http://account.demo.example.com/auth/redirect`
    - `REACT_APP_ALLOWED_SIGN_ORIGINS: ""` <- allowed origin in header `"http://admin.demo.example.com,http://account.demo.example.com"`
  - `admin_host: ` <- `admin` domain
  - `admin_legacy_host: `  <- `admin-legacy` domain
  - `auth_host: `  <- `auth` domain
  - `nhs_portal_host: `  <- `portal` domain
  - `proxy_host: `  <- `proxy` domain
  - `env: `  <- parametr for `helm` env

- install chart with helm
  - `helm install -f fe/values-demo.yaml --name fe fe --namespace fe`

20) For logical replication, it's needed manually to add tables into provider and subscriber, all steps described in `PGLOGICAL.md`

21) For accessing to admin panel it's needed to create user, role, client and connection in mithril database.
- Creating user (login: example@example.com, password: example | and password created in htpasswd)
```sql
INSERT INTO public.users (id, email, password, settings, priv_settings, inserted_at, updated_at, is_blocked, block_reason, password_set_at, tax_id, person_id) VALUES ('f4b30887-07b6-427a-a34d-9e29d88bf497', 'example@example.com', '$apr1$sqVKfHmh$2Ng0qlKlNRCeDZVJZ3Tct.', '{}', '{"login_hstr": [{"time": "2018-07-26T05:31:10.760552", "type": "otp", "is_success": true}, {"time": "2018-07-05T08:48:26.989428", "type": "otp", "is_success": true}, {"time": "2018-07-05T08:47:10.871498", "type": "otp", "is_success": true}], "otp_error_counter": 0}', '2017-05-28 08:25:46.547953', '2019-01-22 09:57:21.824112', 'false', NULL, '2019-01-20 12:00:00.000000', '', '');
```
- Creating client
If sql raise error, perhaps firstly you need to create `client type` using unique `id`, than recreate client inserting that id into `client_type_id` field.
```sql
INSERT INTO public.clients (id, name, settings, priv_settings, user_id, inserted_at, updated_at, client_type_id, is_blocked, block_reason, redirect_uri) VALUES ('73ea1d7f-3d49-4fc9-a25d-f827d29b2ba5', 'eHealth Dev NHS Admin', '{}', '{"access_type": "DIRECT", "broker_scope": "bl_user:deactivate bl_user:read bl_user:write declaration:approve declaration:approve declaration:read declaration:reject declaration:write declaration_documents:read declaration_request:read declaration_request:write dictionary:write employee:deactivate employee:read employee:write employee_request:read employee_request:write global_parameters:read global_parameters:write innm:read innm:write innm_dosage:deactivate innm_dosage:read innm_dosage:write legal_entity:deactivate legal_entity:nhs_verify legal_entity:read medical_program:deactivate medical_program:read medical_program:write medication:deactivate medication:read medication:write medication_dispense:read medication_dispense:reject medication_request:details medication_request:read party_user:read person:reset_authentication_method program_medication:read program_medication:write user:approve_factor user:request_factor reimbursement_report:read reimbursement_report:download global_parameters:read global_parameters:write dictionary:write declaration:terminate register:read register:write person:read register_entry:read contract_request:create contract_request:update contract_request:read contract_request:sign contract_request:terminate contract:read capitation_report:read contract:terminate division:read legal_entity:merge related_legal_entities:read legal_entity_merge_ contract:read"}', 'f4b30887-07b6-427a-a34d-9e29d88bf497', '2017-07-19 09:46:23.220795', '2017-07-19 09:46:23.220806', '5dd3005f-3d26-4878-9b8f-14aeeb2711cf', false, null, null);
```

```sql
INSERT INTO public.clients (id, name, settings, priv_settings, user_id, inserted_at, updated_at, client_type_id, is_blocked, block_reason, redirect_uri) VALUES ('e32e51ac-f720-4e42-adb3-67d504f3ad30', 'eHealth Local Legacy NHS Admin', '{"allowed_grant_types": ["password"]}', '{"access_type": "DIRECT", "broker_scope": "bl_user:deactivate bl_user:read bl_user:write declaration:approve declaration:approve declaration:read declaration:reject declaration:write declaration_documents:read declaration_request:read declaration_request:write dictionary:write employee:deactivate employee:read employee:write employee_request:read employee_request:write global_parameters:read global_parameters:write innm:read innm:write innm_dosage:deactivate innm_dosage:read innm_dosage:write legal_entity:deactivate legal_entity:nhs_verify legal_entity:read medical_program:deactivate medical_program:read medical_program:write medication:deactivate medication:read medication:write medication_dispense:read medication_dispense:reject medication_request:details medication_request:read party_user:read person:reset_authentication_method program_medication:read program_medication:write user:approve_factor user:request_factor reimbursement_report:read reimbursement_report:download global_parameters:read global_parameters:write dictionary:write declaration:terminate register:read register:write person:read register_entry:read contract_request:create contract_request:update contract_request:read contract_request:sign contract_request:terminate contract:read capitation_report:read contract:terminate division:read legal_entity:merge related_legal_entities:read legal_entity_merge_"}', 'f4b30887-07b6-427a-a34d-9e29d88bf497', '2017-05-28 08:31:26.151127', '2018-01-10 21:02:40.482644', '5dd3005f-3d26-4878-9b8f-14aeeb2711cf', 'false', 1, '');
```

```sql
INSERT INTO public.clients (id, name, settings, priv_settings, user_id, inserted_at, updated_at, client_type_id, is_blocked, block_reason, redirect_uri) VALUES ('9f81c81a-7bf7-4f19-934a-875f923d334f', 'eHealth Auth', '{"allowed_grant_types": ["password", "digital_signature"]}', '{"access_type": "DIRECT"}', NULL, '2017-05-26 08:08:46.949865', '2017-05-26 08:08:46.949865', 'a819458b-5e55-4612-b9a5-578bfaa885de', 'false', NULL, NULL);
```
- Creating user-role
```sql
INSERT INTO public.user_roles (id, user_id, role_id, client_id, inserted_at, updated_at) VALUES ('6ee99461-00c2-46d4-9bb2-3cdd049391c7', 'f4b30887-07b6-427a-a34d-9e29d88bf497', '469f9177-cc8a-4f9d-a9ae-c448d45afb07', '73ea1d7f-3d49-4fc9-a25d-f827d29b2ba5', '2017-07-19 10:19:23.024514', '2017-07-19 10:19:23.024524');
```
- Creating connection for client
```sql
INSERT INTO public.connections (id, secret, redirect_uri, client_id, consumer_id, inserted_at, updated_at) VALUES ('8ac324d2-65fb-4b5c-bab1-45bc8d264e42', 'd09vQUFlWTZ6Q0RXRDJISldUOVQ3dz09', 'http://admin-legacy.demo.exemple.com/auth/redirect', '73ea1d7f-3d49-4fc9-a25d-f827d29b2ba5', '73ea1d7f-3d49-4fc9-a25d-f827d29b2ba5', '2018-09-11 12:27:56.053914', '2018-09-11 12:27:56.053914');
```

```sql
INSERT INTO public.connections (id, secret, redirect_uri, client_id, consumer_id, inserted_at, updated_at) VALUES ('8b14cb01-5f68-4c63-a337-6b62ef92ae85', 'dKh3nUUKUHRsbkN6VnJBT0RQeHFUUT09', 'http://admin.demo.exemple.com/auth/redirect', '73ea1d7f-3d49-4fc9-a25d-f827d29b2ba5', '73ea1d7f-3d49-4fc9-a25d-f827d29b2ba5', '2018-09-25 12:57:37.136431', '2018-09-25 12:57:37.136431');
```

- Creating clinet_types if they didn't exist in db
```sql
INSERT INTO public.client_types (id, name, scope, inserted_at, updated_at) VALUES ('a819458b-5e55-4612-b9a5-578bfaa885de', 'Auth_FE', 'app:authorize employee_request:approve employee_request:reject user:request_factor user:approve_factor user:change_password', '2017-05-05 13:38:31.504729', '2017-05-05 13:38:31.504740');
```

- After creating all objects it's need to fill valuse in `fe` charts
  - `REACT_APP_CLIENT_ID` with value of `id` from `clients` with name `eHealth Auth`
  - `REACT_APP_CLIENT_SECRET` and `CLIENT_SECRET` with value of `secret` from `connections`, for `admin` and `admin-legacy` must be their values

- More details about scopes can be found at the [following link](https://edenlab.atlassian.net/wiki/x/v5Ue)

22) MIS creating
- create user in mithril db
```sql
INSERT INTO public.users (id, email, password, settings, priv_settings, inserted_at, updated_at, is_blocked, block_reason, password_set_at, tax_id, person_id) VALUES ('f0245119-59f8-4a9c-a811-90d48d26af40', 'example2@examle.com', '$apr1$Us5UCc.q$Eo1CJAlrP.1s3vORuwhEg1', '{}', '{"otp_error_counter": 0, "login_error_counter": 0}', '2017-05-18 09:20:35.887753', '2017-05-18 09:20:35.887838', 'false', NULL, '2020-05-12 13:03:14.335000', '', '');
```
- create client
```sql
INSERT INTO public.clients (id, name, settings, priv_settings, user_id, inserted_at, updated_at, client_type_id, is_blocked, block_reason, redirect_uri) VALUES ('658fa8f0-4d16-4871-ac10-bdfccb28f0f9', 'Test MIS', '{"allowed_grant_types": ["password", "access_token"]}', '{"access_type": "DIRECT", "broker_scope": "capitation_report:read declaration_documents:read contract_request:sign employee:deactivate medication_request_request:reject legal_entity:read declaration_request:sign medication_request:details division:activate employee:details division:deactivate otp:write declaration_request:read employee_request:read employee_request:reject employee_request:write division:read medication_request:resend employee:write declaration_request:write medical_program:deactivate division:details division:write medical_program:read medication_dispense:reject declaration:read medication_request_request:sign drugs:read medication_dispense:process secret:refresh medical_program:write otp:read medication_request_request:write medication_request_request:read medication_request:read medication_dispense:read person:read medication_dispense:write declaration_request:approve employee_request:approve medication_request:reject declaration_request:reject reimbursement_report:read employee:read event:read contract_request:create contract_request:terminate contract:read contract_request:approve contract_request:update contract_request:sign contract_request:read contract:write contract:terminate      client:read connection:read connection:write connection:refresh_secret connection:delete      patient_summary:read related_legal_entities:read encounter:write encounter:read episode:write episode:read job:read condition:read observation:read immunization:read allergy_intolerance:read encounter:cancel service_request:write service_request:read service_request:use"}', 'f0245119-59f8-4a9c-a811-90d48d26af40', '2017-07-05 10:48:27.924986', '2017-12-26 14:48:33.966289', 'f63b71f8-3177-4c66-a614-0abc946f6249', 'false', NULL, NULL);
```
- create role for MIS, if it's does not exist
```sql
INSERT INTO public.roles (id, name, scope, inserted_at, updated_at) VALUES ('85f8e188-a20f-4200-a617-55345c3fd32c', 'MIS USER', 'legal_entity:read legal_entity:write legal_entity:mis_verify role:read user:request_factor user:approve_factor event:read employee_request:read client:read connection:read connection:write connection:refresh_secret connection:delete', '2017-07-12 12:32:35.583000', '2017-07-12 12:32:37.365000');
```
- create user_roles for MIS
```sql
INSERT INTO public.user_roles (id, user_id, role_id, client_id, inserted_at, updated_at) VALUES ('bccc75a4-9382-4b80-bd3d-121e3047d911', 'f0245119-59f8-4a9c-a811-90d48d26af40', '85f8e188-a20f-4200-a617-55345c3fd32c', '658fa8f0-4d16-4871-ac10-bdfccb28f0f9', '2017-07-12 12:35:46.781000', '2017-07-12 12:35:48.510000');
```

## Working with API
- Use following [manual](https://ehealthmisapi1.docs.apiary.io/#reference) to work with API

