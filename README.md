> [!CAUTION]
> This Lua script prevents bots, but it is also possible that a malicious person could manually retrieve cookies.
> Use rate limiting or other detection in conjunction.
> Also, configure `haproxy.cfg` to allow crawler IPs such as Google bot, as it may affect search.

# haproxy-recaptcha
Require reCAPTCHA authentication when accessing the site.

# Demo
You can view at https://siyukatu.com/ and related sites.

# haproxy configure demo
`haproxy.cfg`
```
global
    lua-load /etc/haproxy/antiddos.lua

frontend http
    bind *:80
    acl antiddosdir path -m beg /.antiddos/
    use_backend antiddosdir if antiddosdir
    use_backend %[lua.capcheck]

backend origin
    server server1 127.0.0.1:3000

backend webcaptcha
    http-request use-service lua.authbot
```

# Dependencies
- Lua (Recommended 5.3.6)
