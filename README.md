# OPA Kong Plugin
_Created to work with [Kong v0.13.x](https://docs.konghq.com/0.13.x/)_

Custom Kong plugin to allow for fine grained Authorization through [Open Policy Agent](https://www.openpolicyagent.org/).

Plugin will continue the request to the upstream target if OPA responds with `true`, else the plugin will return a `401 Not Authorized`.

Requests will add the header `X-Kong-Authz-Latency` to requests which have been impacted by the plugin.

## Setup

### Config
|Parameter                    | Usage                                                                                                       | Type    |
|-----------------------------|-------------------------------------------------------------------------------------------------------------|---------|
|`timeout`                    |timeout in ms for request to OPA                                                                             |`number` |
|`keepalive`                  |keepalive in ms for request to OPA                                                                           |`number` |
|`opa_host`                   |target OPA base address (e.g. `https://authz.example.com`)                                                   |`string` |
|`policy_uri`                 |target OPA policy (e.g. `/v1/data/my_policy`)                                                                |`string` |
|`port`                       |target OPA port                                                                                              |`number` |
|`forward_request_method`     |flag to forward request method                                                                               |`boolean`|
|`forward_request_uri`        |flag to forward request uri                                                                                  |`boolean`|
|`forward_request_headers`    |flag to forward request headers                                                                              |`boolean`|
|`forward_request_body`       |flag to forward request body                                                                                 |`boolean`|
|`forward_upstream_split_path`|flag to forward split upstream path (e.g. `/path/to/my/endpoint` becomes `["path", "to", "my", "endpoint"]`) |`boolean`|
|`debug`                      |flag to return response from OPA - not the upstream target (used for testing purposes)                       |`boolean`|

#### Example

```
$ curl -i -X POST \
  --url http://localhost:9001/services/my-service/plugins/ \
  --data 'name=opa' \
  --data 'config.opa_host=http://localhost:7001' \
  --data 'config.policy_uri=v1/data/my_package/my_policy'
```