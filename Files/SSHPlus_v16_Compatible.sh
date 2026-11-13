#!/bin/sh

# PeDitXOS Tools - SSHPlus Installer (v16 - APK/OPKG Compatible)
# This script installs the SSHPlus service and its LuCI interface.
# Fixes: Adds a final ASCII art banner upon successful installation.

echo ">>> Starting SSHPlus Installation (v16 APK/OPKG Compatible)..."

# Create config file if it doesn't exist
echo "Creating configuration file..."
[ -f /etc/config/sshplus ] || cat > /etc/config/sshplus <<'EoL'
config sshplus 'global'
	option active_profile ''
config profile
	option host 'host.example.com'
	option user 'root'
	option port '22'
	option auth_method 'password'
	option pass 'your_password'
	option key_file '/root/.ssh/id_rsa'
EoL

# Detect the package manager.
# OpenWrt 24.10 and older use opkg; OpenWrt 25.12 and newer use apk.
if command -v apk >/dev/null 2>&1; then
    PKG_MANAGER="apk"
    echo "Detected APK package manager."
elif command -v opkg >/dev/null 2>&1; then
    PKG_MANAGER="opkg"
    echo "Detected OPKG package manager."
else
    echo "ERROR: Neither apk nor opkg was found. This does not appear to be a supported OpenWrt system."
    exit 1
fi

echo "Updating package lists..."
if [ "$PKG_MANAGER" = "apk" ]; then
    apk update
else
    opkg update
fi
if [ $? -ne 0 ]; then
    echo "--------------------------------------------------"
    echo "ERROR: Failed to update package lists."
    echo "Check internet access, system time, DNS and package repository configuration."
    echo "--------------------------------------------------"
    exit 1
fi

# Install only the packages required by this service.
# Package names are available in the official OpenWrt 25.12 APK feeds.
REQUIRED_PACKAGES="curl openssh-client sshpass procps-ng-pgrep luci-base"
echo "Installing required packages: $REQUIRED_PACKAGES"
if [ "$PKG_MANAGER" = "apk" ]; then
    apk add $REQUIRED_PACKAGES
else
    opkg install $REQUIRED_PACKAGES
fi
if [ $? -ne 0 ]; then
    echo "--------------------------------------------------"
    echo "ERROR: Package installation failed."
    echo "Review the package-manager output above."
    echo "--------------------------------------------------"
    exit 1
fi

# Verify the commands actually needed by SSHPlus.
MISSING_TOOLS=""
for tool in curl ssh sshpass pgrep; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done
if [ -n "$MISSING_TOOLS" ]; then
    echo "ERROR: Required commands are still missing:$MISSING_TOOLS"
    exit 1
fi

echo "Creating LuCI files..."
# Verify that the LuCI Lua framework is installed before writing its controller.
if [ ! -f /usr/lib/lua/luci/dispatcher.lua ]; then
    echo "ERROR: LuCI Lua framework was not found after installing luci-base."
    echo "Check that this firmware provides the legacy Lua LuCI controller interface."
    exit 1
fi

# Create necessary directories
mkdir -p /usr/lib/lua/luci/controller /usr/lib/lua/luci/model/cbi /usr/lib/lua/luci/view || {
    echo "ERROR: Could not create LuCI directories."
    exit 1
}
if [ ! -d /usr/lib/lua/luci/controller ] || [ ! -d /usr/lib/lua/luci/model/cbi ] || [ ! -d /usr/lib/lua/luci/view ]; then
    echo "ERROR: LuCI Lua directories are unavailable. Make sure luci-base is installed."
    exit 1
fi

# Create LuCI Controller
cat > /usr/lib/lua/luci/controller/sshplus.lua <<'EoL'
module("luci.controller.sshplus", package.seeall)
function index()
	if not nixio.fs.access("/etc/init.d/sshplus") then return end
	-- FIX: Changed menu path to /admin/peditxos/sshplus and set order to 10
	entry({"admin", "peditxos"}, firstchild(), "Panel Tools", 40).dependent=true
	entry({"admin", "peditxos", "sshplus"}, cbi("sshplus_manager"), "SSH Plus", 10).dependent = true
	entry({"admin", "peditxos", "sshplus_api"}, call("api_handler")).leaf = true
end
function api_handler()
	local action = luci.http.formvalue("action")
	if action == "status" then
		local running = (luci.sys.call("pgrep -f '[s]sh.*-D 127.0.0.1:8089' >/dev/null 2>&1") == 0)
		local ip = "N/A"; local uptime = 0; local active_profile_id = luci.sys.exec("uci get sshplus.global.active_profile 2>/dev/null"):gsub("\n","")
		local active_profile_name = "None"
		if active_profile_id ~= "" then
			local user = luci.sys.exec("uci get sshplus." .. active_profile_id .. ".user 2>/dev/null"):gsub("\n","")
			local host = luci.sys.exec("uci get sshplus." .. active_profile_id .. ".host 2>/dev/null"):gsub("\n","")
			if user ~= "" and host ~= "" then active_profile_name = user .. "@" .. host else active_profile_name = active_profile_id end
		end
		if running then
			local f = io.open("/tmp/sshplus_start_time", "r")
			if f then local start_time = tonumber(f:read("*l") or "0"); f:close(); if start_time > 0 then uptime = os.time() - start_time end end
			local ip_handle = io.popen("curl --max-time 5 --socks5 127.0.0.1:8089 -fsS http://ifconfig.me/ip 2>/dev/null")
			if ip_handle then
				ip = (ip_handle:read("*a") or ""):gsub("\\n", "")
				ip_handle:close()
			end
			if ip == "" then ip = "Checking..." end
		end
		luci.http.prepare_content("application/json"); luci.http.write_json({running = running, ip = ip, uptime = uptime, profile = active_profile_name})
	elseif action == "toggle" then
		local is_running = (luci.sys.call("pgrep -f '[s]sh.*-D 127.0.0.1:8089' >/dev/null 2>&1") == 0)
		if is_running then
			luci.sys.call("/etc/init.d/sshplus stop")
		else
			luci.sys.call("/etc/init.d/sshplus start")
		end
		luci.http.status(200, "OK")
	elseif action == "log" then
		local log_content = ""
		local f = io.open("/tmp/sshplus.log", "r")
		if f then log_content = f:read("*a"); f:close() end
		luci.http.prepare_content("application/json"); luci.http.write_json({log = log_content})
	elseif action == "clear_log" then
		luci.sys.call("date > /tmp/sshplus.log")
		luci.http.status(200, "OK")
	else
		luci.http.status(400, "Bad Request")
		luci.http.write("Unknown action")
	end
end
EoL

# Create LuCI Model (No changes)
cat > /usr/lib/lua/luci/model/cbi/sshplus_manager.lua <<'EoL'
local m = Map("sshplus", "SSHPlus Manager", "Manage status and profiles for your SSH tunnel.")
local s_status = m:section(SimpleSection, "Status & Control"); s_status.template = "sshplus_status_section"
local s_global = m:section(TypedSection, "sshplus", "Global Settings"); s_global.anonymous = true; s_global.addremove = false
local active_profile = s_global:option(ListValue, "active_profile", "Active Profile")
active_profile:value("", "-- Select Profile --")
m.uci:foreach("sshplus", "profile", function(s) active_profile:value(s[".name"], string.format("%s@%s", s.user or "user", s.host or "host")) end)
local s_profiles = m:section(TypedSection, "profile", "Connection Profiles"); s_profiles.anonymous = false; s_profiles.addremove = true; s_profiles.sortable = true
s_profiles:option(Value, "host", "SSH Host/IP"); s_profiles:option(Value, "user", "SSH Username"); s_profiles:option(Value, "port", "SSH Port", "Default is 22").placeholder = "22"
local auth = s_profiles:option(ListValue, "auth_method", "Auth Method"); auth:value("password", "Password"); auth:value("key", "Private Key")
local pass = s_profiles:option(Value, "pass", "SSH Password"); pass.password = true; pass:depends("auth_method", "password")
local keyfile = s_profiles:option(Value, "key_file", "Private Key Path"); keyfile:depends("auth_method", "key"); keyfile.placeholder = "/root/.ssh/id_rsa"
return m
EoL

# Create LuCI View
cat > /usr/lib/lua/luci/view/sshplus_status_section.htm <<'EoL'
<style>
.sshplus-main-container{width:95%;max-width:1200px;margin:20px auto;background:rgba(0,0,0,0.4);-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px);border:1px solid rgba(255,255,255,0.1);border-radius:.75rem;padding:25px;box-shadow:0 8px 32px 0 rgba(0,0,0,0.37)}
.sshplus-layout{display:flex;gap:20px}
.sshplus-log-viewer{flex:1;background-color:#1e1e1e;color:#d4d4d4;font-family:monospace;font-size:0.85em;padding:15px;border-radius:5px;height:280px;overflow-y:scroll;white-space:pre-wrap;border:1px solid rgba(255,255,255,0.1)}
.sshplus-status-panel{flex:0 0 250px;color:#f0f0f0}
.sshplus-status-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:18px;font-size:1.05em}
.sshplus-status-label{color:#c0c0c0}
.sshplus-status-value{font-weight:700;color:#00b5e2;text-align:right}
.sshplus-status-state{font-weight:700;color:#38db8b}
.sshplus-status-state.disconnected{color:#ff4d4d}
.sshplus-actions{margin-top:20px;display:flex;gap:10px}
.sshplus-btn{flex:1;color:#fff;font-size:1.1em;border-radius:5px;padding:10px;border:none;cursor:pointer;font-weight:700;transition:background-color .3s}
.sshplus-btn.disconnect{background:#ff4d4d}
.sshplus-btn.connect{background:#38db8b}
.sshplus-btn:hover{opacity:0.9}
.sshplus-btn:disabled{opacity:0.5;cursor:not-allowed}
.sshplus-btn-clear{background-color:#555;padding:10px 15px}
@media(max-width:700px){.sshplus-layout{flex-direction:column}.sshplus-status-panel{flex:auto}.sshplus-log-viewer{height:240px}}
</style>
<div class="sshplus-main-container">
	<div class="sshplus-layout">
        <!-- FIX: Swapped the position of status panel and log viewer -->
		<div class="sshplus-status-panel">
			<div class="sshplus-status-row"><span class="sshplus-status-label">Profile</span><span id="profileText" class="sshplus-status-value">-</span></div>
			<div class="sshplus-status-row"><span class="sshplus-status-label">Status</span><span id="statusText" class="sshplus-status-state">Checking...</span></div>
			<div class="sshplus-status-row"><span class="sshplus-status-label">IP</span><span id="ipText" class="sshplus-status-value">-</span></div>
			<div class="sshplus-status-row"><span class="sshplus-status-label">Uptime</span><span id="uptimeText" class="sshplus-status-value">-</span></div>
			<div class="sshplus-actions">
				<button class="sshplus-btn" id="mainBtn" onclick="toggleService()"></button>
				<button class="sshplus-btn sshplus-btn-clear" onclick="clearLog()" title="Clear Log">✖</button>
			</div>
		</div>
		<pre id="logViewer" class="sshplus-log-viewer">Loading log...</pre>
	</div>
</div>
<script>
var logPollInterval;
function formatUptime(s){if(isNaN(s)||s<=0)return"-";let h=Math.floor(s/3600);s%=3600;let m=Math.floor(s/60);s=Math.floor(s%60);let t=[];if(h>0){t.push(h+"h")}if(m>0){t.push(m+"m")}if(s>0||t.length===0){t.push(s+"s")}return t.join(" ")}
function updateStatus(){XHR.get('<%=luci.dispatcher.build_url("admin/peditxos/sshplus_api")%>?action=status',null,function(x,st){if(!st)return;let r=st.running,ip=st.ip?.trim()||"N/A",up=st.uptime||0,p=st.profile||"None";let s=document.getElementById("statusText");s.innerHTML=r?"Connected":"Disconnected";s.className="sshplus-status-state"+(r?"":" disconnected");document.getElementById("ipText").innerText=ip;document.getElementById("uptimeText").innerText=formatUptime(up);document.getElementById("profileText").innerText=p;let b=document.getElementById("mainBtn");b.className="sshplus-btn"+(r?" disconnect":" connect");b.innerText=r?"Disconnect":"Connect"})}
function pollLog(){XHR.get('<%=luci.dispatcher.build_url("admin/peditxos/sshplus_api")%>?action=log',null,function(x,st){if(!st)return;var v=document.getElementById("logViewer");var isScrolledBottom=v.scrollHeight-v.clientHeight<=v.scrollTop+5;var logText=st.log||"Log is empty.";if(v.textContent!==logText){v.textContent=logText;if(isScrolledBottom){v.scrollTop=v.scrollHeight}}})}
function toggleService(){var b=document.getElementById("mainBtn");b.disabled=true;XHR.get('<%=luci.dispatcher.build_url("admin/peditxos/sshplus_api")%>?action=toggle',null,function(){setTimeout(function(){updateStatus();pollLog();b.disabled=false},2000)})}
function clearLog(){XHR.get('<%=luci.dispatcher.build_url("admin/peditxos/sshplus_api")%>?action=clear_log',null,function(){pollLog()})}
function startPolling(){if(!logPollInterval){logPollInterval=setInterval(function(){updateStatus();pollLog()},2500)}updateStatus();pollLog()}
window.addEventListener('load',startPolling);
</script>
EoL

echo "Creating service files..."
# Create init.d service script.
cat > /etc/init.d/sshplus <<'EoL'
#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROCD=1
LOG_FILE="/tmp/sshplus.log"

start_service() {
    echo "--- SSHPlus Service Starting at $(date) ---" > "$LOG_FILE"
    procd_open_instance
    procd_set_param command /usr/bin/sshplus_service
    procd_set_param respawn 3600 5 5
    procd_close_instance
}

stop_service() {
    echo "--- SSHPlus Service Stopping at $(date) ---" >> "$LOG_FILE"
    rm -f /tmp/sshplus_start_time
}
EoL
chmod +x /etc/init.d/sshplus

# Create the main SSH tunnel service.
cat > /usr/bin/sshplus_service <<'EoL'
#!/bin/sh

SSH_BIN="$(command -v ssh 2>/dev/null)"
SSHPASS_BIN="$(command -v sshpass 2>/dev/null)"

if [ -z "$SSH_BIN" ] || [ ! -x "$SSH_BIN" ]; then
    echo "FATAL ERROR: OpenSSH client (ssh) was not found."
    sleep 300
    exit 1
fi

while true; do
    ACTIVE_PROFILE="$(uci -q get sshplus.global.active_profile 2>/dev/null)"

    if [ -z "$ACTIVE_PROFILE" ]; then
        echo "ERROR: No active SSHPlus profile is selected."
        echo "Select a profile in LuCI and save. Retrying in 60 seconds..."
        sleep 60
        continue
    fi

    # Validate the UCI section name before using it in UCI queries.
    case "$ACTIVE_PROFILE" in
        *[!A-Za-z0-9_]*|"")
            echo "ERROR: Invalid active profile name: $ACTIVE_PROFILE"
            sleep 60
            continue
            ;;
    esac

    HOST="$(uci -q get "sshplus.$ACTIVE_PROFILE.host" 2>/dev/null)"
    USER_NAME="$(uci -q get "sshplus.$ACTIVE_PROFILE.user" 2>/dev/null)"
    PORT="$(uci -q get "sshplus.$ACTIVE_PROFILE.port" 2>/dev/null)"
    AUTH_METHOD="$(uci -q get "sshplus.$ACTIVE_PROFILE.auth_method" 2>/dev/null)"
    PASS="$(uci -q get "sshplus.$ACTIVE_PROFILE.pass" 2>/dev/null)"
    KEY_FILE="$(uci -q get "sshplus.$ACTIVE_PROFILE.key_file" 2>/dev/null)"

    if [ -z "$HOST" ] || [ -z "$USER_NAME" ]; then
        echo "ERROR: Profile '$ACTIVE_PROFILE' requires an SSH host and username."
        sleep 60
        continue
    fi

    case "$PORT" in
        ''|*[!0-9]*)
            echo "ERROR: Invalid SSH port in profile '$ACTIVE_PROFILE': $PORT"
            sleep 60
            continue
            ;;
    esac
    if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo "ERROR: SSH port must be between 1 and 65535."
        sleep 60
        continue
    fi

    echo "Connecting profile '$ACTIVE_PROFILE' to $USER_NAME@$HOST:$PORT"
    date +%s > /tmp/sshplus_start_time

    # Build arguments safely; avoid splitting host, user, port or key-file values.
    set -- -v -T \
        -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=3 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=15 \
        -o ExitOnForwardFailure=yes \
        -D 127.0.0.1:8089 \
        -N -p "$PORT" "$USER_NAME@$HOST"

    if [ "$AUTH_METHOD" = "key" ]; then
        if [ -z "$KEY_FILE" ] || [ ! -r "$KEY_FILE" ]; then
            echo "ERROR: Private key file is missing or unreadable: $KEY_FILE"
            rm -f /tmp/sshplus_start_time
            sleep 60
            continue
        fi
        echo "Authentication method: private key."
        "$SSH_BIN" -i "$KEY_FILE" "$@"
        SSH_EXIT_CODE=$?
    else
        if [ -z "$SSHPASS_BIN" ] || [ ! -x "$SSHPASS_BIN" ]; then
            echo "FATAL ERROR: sshpass was not found."
            rm -f /tmp/sshplus_start_time
            sleep 300
            exit 1
        fi
        if [ -z "$PASS" ]; then
            echo "ERROR: Password is empty for profile '$ACTIVE_PROFILE'."
            rm -f /tmp/sshplus_start_time
            sleep 60
            continue
        fi
        echo "Authentication method: password."
        SSHPASS="$PASS"
        export SSHPASS
        "$SSHPASS_BIN" -e "$SSH_BIN" "$@"
        SSH_EXIT_CODE=$?
        unset SSHPASS
    fi

    echo "SSH tunnel disconnected. Exit code: $SSH_EXIT_CODE. Reconnecting in 5 seconds..."
    rm -f /tmp/sshplus_start_time
    sleep 5
done
EoL
chmod +x /usr/bin/sshplus_service

# Replaced with the new, more detailed Passwall configuration logic.
echo "Configuring Passwall/Passwall2 if present..."
if [ -x /etc/init.d/passwall2 ] && [ -f /etc/config/passwall2 ]; then
    uci set passwall2.SshPlus=nodes || exit 1
    uci set passwall2.SshPlus.remarks='SSH Plus'
    uci set passwall2.SshPlus.type='Xray'
    uci set passwall2.SshPlus.protocol='socks'
    uci set passwall2.SshPlus.server='127.0.0.1'
    uci set passwall2.SshPlus.port='8089'
    uci set passwall2.SshPlus.address='127.0.0.1'
    uci set passwall2.SshPlus.tls='0'
    uci set passwall2.SshPlus.transport='tcp'
    uci set passwall2.SshPlus.tcp_guise='none'
    uci set passwall2.SshPlus.tcpMptcp='0'
    uci set passwall2.SshPlus.tcpNoDelay='0'
    uci commit passwall2 || {
        echo "WARNING: Could not commit Passwall2 configuration."
    }
    echo "Passwall2 configuration updated."
elif [ -x /etc/init.d/passwall ] && [ -f /etc/config/passwall ]; then
    uci set passwall.SshPlus=nodes || exit 1
    uci set passwall.SshPlus.remarks='SSH Plus'
    uci set passwall.SshPlus.type='Xray'
    uci set passwall.SshPlus.protocol='socks'
    uci set passwall.SshPlus.server='127.0.0.1'
    uci set passwall.SshPlus.port='8089'
    uci set passwall.SshPlus.address='127.0.0.1'
    uci set passwall.SshPlus.tls='0'
    uci set passwall.SshPlus.transport='tcp'
    uci set passwall.SshPlus.tcp_guise='none'
    uci set passwall.SshPlus.tcpMptcp='0'
    uci set passwall.SshPlus.tcpNoDelay='0'
    uci commit passwall || {
        echo "WARNING: Could not commit Passwall configuration."
    }
    echo "Passwall configuration updated."
else
    echo "Neither Passwall nor Passwall2 is installed. Skipping configuration."
fi


# Service is now enabled and restarted at the end, after all files are created.
echo "Enabling and restarting the service..."
/etc/init.d/sshplus enable || {
    echo "ERROR: Failed to enable SSHPlus at boot."
    exit 1
}
/etc/init.d/sshplus restart || {
    echo "ERROR: Failed to restart SSHPlus."
    exit 1
}

echo ">>> SSHPlus installation/update complete."

# FIX: Added final ASCII art banner
cat << "EoL"

Installation was Successful

EoL
