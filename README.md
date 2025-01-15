> [!CAUTION]
> This Lua script prevents bots, but it is also possible that a malicious person could manually retrieve cookies.<br>
> Use rate limiting or other detection in conjunction.<br>
> Also, configure `haproxy.cfg` to allow crawler IPs such as Google bot, as it may affect search.

# haproxy-recaptcha
Require reCAPTCHA authentication when accessing the site.

# Demo
You can view at https://siyukatu.com/ and related sites.

# Setup
1. In root, `wget -O /etc/haproxy/captcha.lua https://raw.githubusercontent.com/siyukatu/haproxy-recaptcha/refs/heads/main/captcha.lua`
2. Create reCAPTCHA site (v2 and v3)
3. Edit `/etc/haproxy/captcha.lua`
    1. Chagne `antiddossecret` (Recommended 256 Length Password)
    2. Change `recaptcha_v3_secret` and `recaptcha_v3_sitekey`
    3. Chagne `recaptcha_v2_secret` and `recaptcha_v2_sitekey`
    4. Change `origin_frontend` and `webcaptcha_frontend` (Reference "HAProxy Configure Demo")
    5. (Any) Change `colors_preset`

# HAProxy Configure Demo
`haproxy.cfg`
```
global
    lua-load /etc/haproxy/captcha.lua

frontend http
    bind *:80
    use_backend %[lua.capcheck]

backend origin
    server server1 127.0.0.1:3000

backend webcaptcha
    http-request use-service lua.authbot
```

# Dependencies
- HAProxy (Any version)
- Lua (5.3.6 or less)
- [lua-requests](https://github.com/JakobGreen/lua-requests) (Recommended 1.2-1)
- [pure_lua_SHA](https://github.com/Egor-Skriptunoff/pure_lua_SHA) (Latest)
- lua-cjson (luarocks, Recommended 2.1.0.10-1)
