local json = require("cjson")
local sha = require("sha2")
local requests = require('requests')

-- [config zone]
local antiddossecret = "" -- Recommended 256 or more Length Password

local recaptcha_v3_secret = ""
local recaptcha_v3_sitekey = ""

local recaptcha_v3_threshold = 0.5 -- if score is lower than this, show recaptcha v2. (0.0 ~ 1.0)

local recaptcha_v2_secret = ""
local recaptcha_v2_sitekey = ""

local custom_message = "<!-- This website uses https://github.com/siyukatu/haproxy-recaptcha -->" -- custom HTML message to show on the verification page

local origin_frontend = "origin"
local webcaptcha_frontend = "webcaptcha"

local colors_preset = {
    ["default"] = {
        text = "#222",
        background = "#fff",
        gray = "#ccc",
        text_gray = "#777",
        green = "#0c0",
        error = "#ff5050",
        recaptcha = "light"
    },
    ["example.com"] = {
        text = "#222",
        background = "#ccc",
        gray = "#ccc",
        text_gray = "#777",
        green = "#0c0",
        error = "#ff5050",
        recaptcha = "light"
    }
}
-- end of config zone

local function table_to_encoded_url(args)
    local params = {}
    for k, v in pairs(args) do table.insert(params, k .. '=' .. v) end
    return table.concat(params, "&")
end

local function parse_kv(s, sep)
    if s == nil then return nil end
    idx = 1
    result = {}

    while idx < s:len() do
        i, j = s:find(sep, idx)

        if i == nil then
            k, v = string.match(s:sub(idx), "^(.-)=(.*)$")
            if k then result[k] = v end
            break
        end

        k, v = string.match(s:sub(idx, i-1), "^(.-)=(.*)$")
        if k then result[k] = v end
        idx = j + 1
    end

    if next(result) == nil then
        return nil
    else
        return result
    end
end

local function isset_table(name,table)
    if table == nil then
        return false
    end
    for key, value in pairs(table) do
        if key == name then
            return true
        end
    end
    return false
end

local function generate_notbot(srcip)
    return sha.sha256(srcip..antiddossecret)
end

local function verify_notbot(notbot,srcip)
    local iphash = generate_notbot(srcip)
    if iphash == notbot then
        return true
    end
    return false
end

function match_allowed_domain(origin_header, allowed_domains)
    for _, domain in ipairs(allowed_domains) do
        if string.match(origin_header, "^https://.-" .. (domain:gsub("%.", "%%.")) .. "$") then
            return true
        end
    end
    return false
end

local function authbot(applet)
    local langs = {
        ["ja"] = {
            title = "接続認証",
            error = "エラー",
            noscript_message = "このページの表示にはJavaScriptが必要です。",
            howtoenablejs = "有効化について",
            pleasewaitamoment = "しばらくお待ちください",
            loading = "読み込み中",
            verifying = "認証中",
            checking = "確認中",
            network_error = "接続エラー",
            redirecting = "リダイレクト中",
            complete_robot_auth = "ロボット認証を完了させてください",
            reloading = "再読み込み中",
            please_retry = "もう一度お試し下さい"
        },
        ["en-us"] = {
            title = "Connection Authentication",
            error = "Error",
            noscript_message = "JavaScript is required to display this page.",
            howtoenablejs = "How to Enable",
            pleasewaitamoment = "Please wait a moment",
            loading = "Loading",
            verifying = "Verifying",
            checking = "Checking",
            network_error = "Connection Error",
            redirecting = "Redirecting",
            complete_robot_auth = "Please complete the robot authentication",
            reloading = "Reloading",
            please_retry = "Please try again"
        },
        ["ko"] = {
            title = "연결 인증",
            error = "오류",
            noscript_message = "이 페이지를 표시하려면 JavaScript가 필요합니다.",
            howtoenablejs = "활성화 방법",
            pleasewaitamoment = "잠시만 기다려 주십시오",
            loading = "로딩 중",
            verifying = "인증 중",
            checking = "확인 중",
            network_error = "연결 오류",
            redirecting = "리디렉션 중",
            complete_robot_auth = "로봇 인증을 완료하십시오",
            reloading = "재로딩 중",
            please_retry = "다시 시도하십시오"
        }
    }
    local colors = colors_preset["default"]
    local host = applet.headers["host"]
    if type(host) == "table" then
        host = host[0]
    end
    if colors_preset[host] then
        colors = colors_preset[host]
    end
    local lang = "ja"
    local accept_language = applet.headers["accept-language"]
    if type(accept_language) == "table" then
        accept_language = accept_language[0]
    end
    if accept_language then
        for lang_code in string.gmatch(accept_language:lower(), '([^,]+)') do
            lang_code = lang_code:match("^%s*([^;]+)%s*")
            if langs[lang_code] then
                lang = lang_code
                break
            end
        end
    end
    local langdata = langs[lang]
    local response = [[<!DOCTYPE html>
<html lang="ja"><head><title>]]..langdata["title"]..[[</title><style>.status_text{display:block;transition:all .25s ease;font-size:16px;animation:addstatus .25s ease;}.status_text.done{font-size:12px;color:]]..colors["text_gray"]..[[;animation:none;}.spinner,.spinner:after, .checkspinner, .checkspinner:after{border-radius:50%;width:24px;height:24px;}.spinner{margin:0px auto;font-size:3px;text-indent:-9999em;border:3px solid ]]..colors["gray"]..[[;border-left:3px solid ]]..colors["text"]..[[;transform:translateZ(0);animation:spin 0.4s infinite linear;}.checkspinner{margin:0px auto;font-size:3px;border:3px solid ]]..colors["green"]..[[;transform:translateZ(0);}@keyframes spin{0%{transform:rotate(0deg);}100%{transform:rotate(360deg);}}@keyframes addstatus{0%{font-size:0px;}100%{font-size:16px;}}.spinner .checkmark{display:none;}.checkspinner .checkmark{display:block;margin:20% auto;width:50%;height:30%;border-left:2.5px solid ]]..colors["green"]..[[;border-bottom: 2.5px solid ]]..colors["green"]..[[;transform:rotate(-45deg);}</style><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="font-family:sans-serif;background:]]..colors["background"]..[[;color:]]..colors["text"]..[[;display:flex;position:fixed;width:100%;height:100%;margin:0px;"><noscript><div style="position:fixed;z-index:10000;height:calc(100% - 20px);width:calc(100% - 20px);top:0px;left:0px;background:rgba(0,0,0,0.8);display:flex;padding:10px;"><div style="margin:auto;background:]]..colors["background"]..[[;padding:15px;"><span style="font-size:1.8em;">]]..langdata["error"]..[[</span><br>]]..langdata["noscript_message"]..[[<br><a href="https://support.google.com/admanager/answer/12654?hl=]]..lang..[[" target="_blank" style="color:white;text-decoration:">]]..langdata["howtoenablejs"]..[[</a></div></div></noscript><div style="text-align:center;margin:auto"><h2><div class="spinner" id="spinner"><div class="checkmark"></div></div><span id="title">]]..langdata["pleasewaitamoment"]..[[</span></h2><div id="v2recaptcha" class="g-recaptcha" data-theme="]]..colors["recaptcha"]..[[" data-callback="donev2" data-sitekey="]]..recaptcha_v2_sitekey..[["></div><div id="recaptcha-message" style="font-size:0.8em;"></div><span id="status"><span class="status_text">]]..langdata["loading"]..[[</span></span></div><script>window.onload = function(){lorev3();};function lorev3(){cs("https://www.google.com/recaptcha/api.js?render=]]..recaptcha_v3_sitekey..[[").onload = function(){gorev3();};};function gorev3(){chstatus("]]..langdata["verifying"]..[[");grecaptcha.ready(function(){grecaptcha.execute(']]..recaptcha_v3_sitekey..[[',{action:'submit'}).then(function(token){chstatus("]]..langdata["checking"]..[[");ajax=new XMLHttpRequest();ajax.open("POST","/antiddos_recaptcha");ajax.onerror=function(){setTimeout(function(){chstatus("]]..langdata["network_error"]..[[");location.reload();},1000);};ajax.onload=function(){if(ajax.responseText=="done"){st(ajax.getResponseHeader("x-notbot"));return;};if(ajax.responseText=="change-v2"){document.getElementById("spinner").style.display="none";document.getElementById("title").style.display="none";chstatus("]]..langdata["complete_robot_auth"]..[[");cs("https://www.google.com/recaptcha/api.js?render=v2recaptcha");return;}chstatus("]]..langdata["reloading"]..[[");setTimeout(function(){location.reload();},250);};ajax.send(token);});});};function donev2(token){document.getElementById("spinner").style.display="";document.getElementById("title").style.display="";document.getElementById("recaptcha-message").innerText="";document.getElementById("v2recaptcha").style.display="none";ajax=new XMLHttpRequest();ajax.open("POST","/antiddos_recaptcha_v2");ajax.onerror=function(){setTimeout(function(){chstatus("]]..langdata["network_error"]..[[");location.reload();},1000);};ajax.onload=function(){if(ajax.responseText=="done"){st(ajax.getResponseHeader("x-notbot"));return;}if (ajax.responseText == "retry"){grecaptcha.reset();document.getElementById("spinner").style.display="none";document.getElementById("title").style.display="none";document.getElementById("v2recaptcha").style.display="";document.getElementById("recaptcha-message").innerText="]]..langdata["please_retry"]..[[";document.getElementById("recaptcha-message").style.color="]]..colors["error"]..[[";return;}chstatus("]]..langdata["reloading"]..[[");setTimeout(function(){location.reload();},250);return;};ajax.send(token);}function chstatus(status){document.querySelectorAll(".status_text").forEach(e=>{e.classList.add("done")});var span=document.createElement("span");span.classList.add("status_text");span.innerText=status;document.getElementById("status").prepend(span);}function cs(r){var s=document.createElement("script");s.src=r;document.head.append(s);return s;};function st(t,host=null,path=null,reload=true){if(host===null){host=window.syktcfg["token_manager"]["host"]}if(path===null){path=window.syktcfg["token_manager"]["path"]}var ajax = new XMLHttpRequest();ajax.open("POST",host+path+"set_notbot");ajax.withCredentials = true;ajax.onload = function(){if(reload){document.getElementById("spinner").style.display="";document.getElementById("title").style.display="";document.getElementById("spinner").className="checkspinner";chstatus("]]..langdata["redirecting"]..[[");setTimeout(function(){location.reload();},250);}};ajax.onerror = function(){ajax.onload();};ajax.send(t);};function onerror(){chstatus("]]..langdata["reloading"]..[[");setTimeout(function(){location.reload();},250);}</script></body></html>
]]..custom_message
    local statuscode = 503
    if applet.method == "POST" and applet.path == "/antiddos_recaptcha" then
        local data = applet:receive()
        local responser = requests.get("https://www.recaptcha.net/recaptcha/api/siteverify?secret="..recaptcha_v3_secret.."&response="..data.."&remoteip="..applet.f:src())
        if responser.json()["success"] == true then
            if responser.json()["score"] >= recaptcha_v3_threshold then
                response = "done"
                local iphash = generate_notbot(applet.f:src())
                applet:add_header("Set-Cookie", "notbot="..iphash.."; Path=/; Max-Age=31536000; SameSite=None; HttpOnly; Secure")
                applet:add_header("x-notbot", iphash)
                statuscode = 200
            else
                response = "change-v2"
                statuscode = 403
            end
        else
            response = "retry"
            statuscode = 400
        end
    end
    if applet.method == "POST" and applet.path == "/antiddos_recaptcha_v2" then
        data = applet:receive()
        local responser = requests.get("https://www.recaptcha.net/recaptcha/api/siteverify?secret="..recaptcha_v2_secret.."&response="..data.."&remoteip="..applet.f:src())
        if responser.json()["success"] == true then
            response = "done"
            local iphash = generate_notbot(applet.f:src())
            applet:add_header("Set-Cookie", "notbot="..iphash.."; Path=/; Max-Age=31536000; SameSite=None; HttpOnly; Secure")
            applet:add_header("x-notbot", iphash)
            statuscode = 200
        else
            response = "retry"
            statuscode = 400
        end
    end
    applet:set_status(statuscode)
    applet:add_header("x-powered-by", "https://github.com/siyukatu/haproxy-recaptcha")
    applet:add_header("content-length", string.len(response))
    applet:add_header("content-type", "text/html; charset=utf-8")
    applet:start_response()
    applet:send(response)
end

local function capcheck(txn)
    if txn.sf:req_fhdr("x-notbot") ~= nil then
        if verify_notbot(txn.sf:req_fhdr("x-notbot"), txn.f:src()) then
            return origin_frontend
        end
    end
    if txn.sf:req_fhdr("cookie") ~= nil then
        local cookies = parse_kv(txn.sf:req_fhdr("cookie"),"; ")
        if isset_table("notbot",cookies) then
            if verify_notbot(cookies["notbot"], txn.f:src()) then
                return origin_frontend
            end
        end
    end
    return webcaptcha_frontend
end

core.register_fetches('capcheck', capcheck)
core.register_service("authbot", "http", authbot)
