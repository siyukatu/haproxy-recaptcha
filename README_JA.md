> [!CAUTION]
> このLuaスクリプトはbotによるアクセスをブロックしますが、善良なbot (Google Botなど)もブロックしてしまう恐れがあります。<br>
> `haproxy.cfg` で善良なbotのIPアドレスだけは許可するようにしてください。

# haproxy-recaptcha
ウェブサイトアクセス時にreCAPTCHA認証を要求するようにします。

# デモ
https://siyukatu.com/ やその関係サイトで見れます。

# 使い方
1. root権限で `wget -O /etc/haproxy/captcha.lua https://raw.githubusercontent.com/siyukatu/haproxy-recaptcha/refs/heads/main/captcha.lua` を実行
2. [reCAPTCHAのadmin](https://www.google.com/recaptcha/admin/create)でv2とv3のサイトを作成してサイトキーとシークレットキーをメモ
3. `/etc/haproxy/captcha.lua` を編集
    1. `antiddossecret` を256文字くらいの文字列に変更 ([パスワード生成ツール](https://idprotect.trendmicro.com/ja/vault/tool/password-generator)とかおすすめ)
    2. `recaptcha_v3_secret` と `recaptcha_v3_sitekey` をさっき生成したキーに変更
    3. `recaptcha_v2_secret` と `recaptcha_v2_sitekey` をさっき生成したキーに変更
    4. `origin_frontend` と `webcaptcha_frontend` をそれぞれ `haproxy.cfg` で使ってる名称に変更
    5. (任意) `colors_preset` を変更 (ページのテーマとか変えられる)

# HAProxy設定デモ
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

# 依存
- HAProxy (基本すべてのバージョンで動作)
- Lua (5.3.6以下)
- [lua-requests](https://github.com/JakobGreen/lua-requests) (推奨 1.2-1)
- [pure_lua_SHA](https://github.com/Egor-Skriptunoff/pure_lua_SHA) (最新)
- lua-cjson (luarocks経由, 推奨 2.1.0.10-1)
