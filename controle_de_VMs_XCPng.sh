#!/bin/bash

XE_USER="root"
XE_PASS="91687008"

PORT=8081
WEB_DIR="/opt/webvm"
CGI_DIR="$WEB_DIR/cgi-bin"

[ "$EUID" -ne 0 ] && exit 1
command -v xe >/dev/null || exit 1
command -v python3 >/dev/null || exit 1

mkdir -p "$CGI_DIR"

cat << EOF > "$WEB_DIR/index.html"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=/cgi-bin/vm.sh">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Redirecionando</title>
</head>
<body>Redirecionando...</body>
</html>
EOF

cat << EOF > "$CGI_DIR/vm.sh"
#!/bin/bash

echo "Content-Type: text/html"
echo ""

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root

XE_USER="$XE_USER"
XE_PASS="$XE_PASS"

xe_cmd() {
    xe -u "\$XE_USER" -pw "\$XE_PASS" "\$@"
}

QUERY="\$QUERY_STRING"
[ "\$REQUEST_METHOD" = "POST" ] && read -r QUERY

ACTION=\$(echo "\$QUERY" | sed -n 's/.*action=\\([^&]*\\).*/\\1/p')
UUID=\$(echo "\$QUERY" | sed -n 's/.*uuid=\\([^&]*\\).*/\\1/p')

if [ -n "\$ACTION" ] && [ -n "\$UUID" ]; then
    case "\$ACTION" in
        start) xe_cmd vm-start uuid="\$UUID" ;;
        stop) xe_cmd vm-shutdown uuid="\$UUID" force=true ;;
        reboot) xe_cmd vm-reboot uuid="\$UUID" force=true ;;
    esac
    echo "Status: 303 See Other"
    echo "Location: /cgi-bin/vm.sh"
    echo ""
    exit 0
fi

cat << HTML
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Controle de VMs</title>
<style>
body{
    font-family:Arial,Helvetica,sans-serif;
    background:#f5f6f7;
    margin:10px;
}

h2{
    margin-bottom:10px;
}

table{
    width:100%;
    border-collapse:collapse;
    background:#fff;
}

th{
    background:#e9ecef;
    text-align:left;
}

td,th{
    border:1px solid #ddd;
    padding:8px;
}

tr:nth-child(even){
    background:#f9f9f9;
}

.running{
    color:#2e7d32;
    font-weight:bold;
}

.halted{
    color:#c62828;
    font-weight:bold;
}

button{
    padding:8px 14px;
    margin:4px 2px;
    border:none;
    background:#1976d2;
    color:#fff;
    cursor:pointer;
    width:100%;
}

form{
    display:inline;
}

/* ===== RESPONSIVO ===== */
@media (max-width: 700px){

    table, thead, tbody, th, td, tr{
        display:block;
    }

    thead{
        display:none;
    }

    tr{
        background:#fff;
        margin-bottom:12px;
        border:1px solid #ddd;
        padding:10px;
    }

    td{
        border:none;
        padding:6px 0;
    }

    td::before{
        font-weight:bold;
        display:block;
        margin-bottom:2px;
    }

    td:nth-child(1)::before{ content:"VM"; }
    td:nth-child(2)::before{ content:"Status"; }
    td:nth-child(3)::before{ content:"Ações"; }

    button{
        width:100%;
    }
}
</style>

</head>
<body>

<h2>Controle de VMs - XCP-ng</h2>

<table>
<thead>
<tr>
<th>Nome</th>
<th>Status</th>
<th>Ações</th>
</tr>
</thead>
<tbody>
HTML

xe_cmd vm-list is-control-domain=false is-a-template=false --minimal | tr ',' '\n' | while read uuid
do
    NAME=\$(xe_cmd vm-param-get uuid="\$uuid" param-name=name-label)
    STATE=\$(xe_cmd vm-param-get uuid="\$uuid" param-name=power-state)

    echo "<tr>"
    echo "<td>\$NAME<br><small>\$uuid</small></td>"
    echo "<td class='\$STATE'>\$STATE</td>"
    echo "<td>"

    if [ "\$STATE" = "running" ]; then
        echo "<form method='POST'>
              <input type='hidden' name='action' value='stop'>
              <input type='hidden' name='uuid' value='\$uuid'>
              <button>Parar</button>
              </form>
              <form method='POST'>
              <input type='hidden' name='action' value='reboot'>
              <input type='hidden' name='uuid' value='\$uuid'>
              <button>Reiniciar</button>
              </form>"
    else
        echo "<form method='POST'>
              <input type='hidden' name='action' value='start'>
              <input type='hidden' name='uuid' value='\$uuid'>
              <button>Iniciar</button>
              </form>"
    fi

    echo "</td></tr>"
done

cat << HTML
</tbody>
</table>

<p>Atualização automática a cada 30 segundos</p>
<script>
setTimeout(function(){location.reload()},30000);
</script>

</body>
</html>
HTML
EOF

chmod +x "$CGI_DIR/vm.sh"

cat << EOF > /etc/systemd/system/webvm.service
[Unit]
Description=Web VM Control
After=network.target xapi.service

[Service]
ExecStart=/usr/bin/python3 -m http.server $PORT --cgi --bind 0.0.0.0
WorkingDirectory=$WEB_DIR
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now webvm

if command -v firewall-cmd >/dev/null; then
    firewall-cmd --permanent --add-port=$PORT/tcp
    firewall-cmd --reload
fi

echo "http://$(hostname -I | awk '{print $1}'):$PORT"
