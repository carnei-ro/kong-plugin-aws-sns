# Kong Plugin AWS SNS

summary: Publishes the body request to an AWS SNS topic

TODO:

- [ ] tests
- [ ] message attributes

Minimal config (when kong is running at AWS):

```yaml
plugins:
  - name: aws-sns
    config:
      topic_arn: arn:aws:sns:us-east-1:000000000000:NotifyMe
      aws_region: us-east-1
```

<!-- BEGINNING OF KONG-PLUGIN DOCS HOOK -->
## Plugin Priority

Priority: **750**

## Plugin Version

Version: **2.0.0**

## config

| name | type | required | validations | default |
|-----|-----|-----|-----|-----|
| timeout | number | <pre>true</pre> |  | <pre>60000</pre> |
| keepalive | number | <pre>true</pre> |  | <pre>60000</pre> |
| aws_key | string | <pre>false</pre> |  |  |
| aws_secret | string | <pre>false</pre> |  |  |
| aws_assume_role_arn | string | <pre>false</pre> |  |  |
| aws_role_session_name | string | <pre>false</pre> |  | <pre>kong</pre> |
| aws_region | string | <pre>false</pre> |  |  |
| topic_arn | string | <pre>true</pre> |  |  |
| host | string | <pre>false</pre> |  |  |
| port | integer | <pre>false</pre> | <pre>- between:<br/>  - 0<br/>  - 65535</pre> | <pre>443</pre> |
| proxy_url | string | <pre>false</pre> |  |  |
| skip_large_bodies | boolean | <pre>false</pre> |  | <pre>false</pre> |
| base64_encode_body | boolean | <pre>false</pre> |  | <pre>false</pre> |

## Usage

```yaml
plugins:
  - name: aws-sns
    enabled: true
    config:
      timeout: 60000
      keepalive: 60000
      aws_key: ''
      aws_secret: ''
      aws_assume_role_arn: ''
      aws_role_session_name: kong
      aws_region: ''
      topic_arn: ''
      host: ''
      port: 443
      proxy_url: ''
      skip_large_bodies: false
      base64_encode_body: false

```
<!-- END OF KONG-PLUGIN DOCS HOOK -->
