# Kongak

[Kong](https://konghq.com/kong-community-edition/) config automation tool

## Features

- [ ] Kong 0.14
- [x] Kong 0.13
- [x] api CRUD operations
- [x] api plugins CRUD operations
- [x] consumers
- [x] certificates
- [x] upstreams
- [x] global plugins
- [ ] acl support
- [ ] parallel requests
- [ ] allow to dump config
- [ ] add dry-run option

## Usage

You should have [elixir](https://elixir-lang.org/install.html) installed (at least 1.6 version is required)

1. `git clone git@github.com:AlexKovalevych/kongak.git`
2. `cd kongak && mix deps.get && mix escript.build`
3. `./kongak apply --host localhost --port 8001 --path config.yaml`

## Config

### **Warning! This library uses config file as a config state source, that means it will create, update and delete all apis, targets, certificates, consumers to make your server config match your config file.** ###

Config file should be in yaml format and can include several items (for now only `apis` is supported).

Each `api` can have fields, defined in [Kong documentation](https://docs.konghq.com/0.12.x/admin-api/#request-body) and `plugins` field with a list of plugins.

Each `plugin` can have `name`, `config`, `consumer_id` and `enabled` fields.

Example config:

```yaml
apis:
  - name: users
    plugins:
      - name: cors
        enabled: true
        config:
          methods:
            - GET
          credentials: false
          headers:
            - Access-Control-Allow-Origin
            - Authorization
            - content-type
            - origin
            - accept
            - access-control-request-headers
            - access-control-request-method
            - pragma
            - cache-control
          origins:
            - '*'
          preflight_continue: false
    uris:
      - /users
    methods:
      - GET
    strip_uri: false
    preserve_host: false
    upstream_url: 'http://api-svc.auth/'
    retries: 5
    upstream_connect_timeout: 60000
    upstream_read_timeout: 60000
    upstream_send_timeout: 60000
    https_only: false
    http_if_terminated: false
```
