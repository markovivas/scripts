#!/bin/bash
# =================================================================
# WEB XCP-NG MANAGER - INSTALAÇÃO E CONFIGURAÇÃO COMPLETA
# =================================================================
# Este script:
# 1. Instala interface web para gerenciar VMs
# 2. Configura auto-inicialização com systemd
# 3. Adiciona verificação periódica (cron)
# =================================================================

set -e

# ===== CONFIGURAÇÕES =====
PORT=8081
WEB_DIR="/opt/webvm"
CGI_DIR="$WEB_DIR/cgi-bin"
LOG_DIR="/var/log/webvm"
XE_USER="root"
XE_PASS="91687008"  # Altere sua senha aqui!

# ===== CORES =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===== FUNÇÕES =====
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${YELLOW}[i]${NC} $1"; }
print_step() { echo -e "\n${BLUE}[+]${NC} $1"; }

# ===== VALIDAÇÕES INICIAIS =====
validate_prerequisites() {
    print_step "Validando pré-requisitos"
    
    # Verificar root
    if [ "$EUID" -ne 0 ]; then
        print_error "Execute como root: sudo $0"
        exit 1
    fi
    
    # Verificar comandos necessários
    for cmd in xe python3; do
        if ! command -v $cmd >/dev/null; then
            print_error "$cmd não encontrado"
            exit 1
        fi
    done
    print_success "Pré-requisitos OK"
}

# ===== INSTALAR WEB INTERFACE =====
install_web_interface() {
    print_step "Instalando interface web"
    
    # Criar diretórios
    mkdir -p "$WEB_DIR" "$CGI_DIR" "$LOG_DIR"
    
    # Criar index.html com redirecionamento
    cat > "$WEB_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=/cgi-bin/vm.sh">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>XCP-ng VM Manager</title>
<style>
body {
    font-family: Arial, sans-serif;
    text-align: center;
    padding: 50px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
}
.spinner {
    border: 8px solid rgba(255,255,255,0.3);
    border-radius: 50%;
    border-top: 8px solid white;
    width: 60px;
    height: 60px;
    animation: spin 1s linear infinite;
    margin: 20px;
}
@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}
h1 {
    margin: 20px 0;
    font-size: 2.5em;
}
p {
    font-size: 1.2em;
    opacity: 0.9;
}
</style>
</head>
<body>
    <div class="spinner"></div>
    <h1>XCP-ng VM Manager</h1>
    <p>Carregando interface de controle...</p>
    <p>Se o redirecionamento não funcionar, <a href="/cgi-bin/vm.sh" style="color:#fff;text-decoration:underline;">clique aqui</a></p>
</body>
</html>
EOF
    
    # Criar script CGI principal
    cat > "$CGI_DIR/vm.sh" << 'EOF'
#!/bin/bash
echo "Content-Type: text/html; charset=utf-8"
echo ""

# Configurações
XE_USER="root"
XE_PASS="91687008"
export PATH=/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root

# Função para executar comandos xe
xe_cmd() {
    xe -u "$XE_USER" -pw "$XE_PASS" "$@" 2>/dev/null
}

# Processar ações
if [ "$REQUEST_METHOD" = "POST" ]; then
    read -r QUERY
    ACTION=$(echo "$QUERY" | sed -n 's/.*action=\([^&]*\).*/\1/p')
    UUID=$(echo "$QUERY" | sed -n 's/.*uuid=\([^&]*\).*/\1/p')
    
    if [ -n "$ACTION" ] && [ -n "$UUID" ]; then
        case "$ACTION" in
            start)   xe_cmd vm-start uuid="$UUID" ;;
            stop)    xe_cmd vm-shutdown uuid="$UUID" force=true ;;
            reboot)  xe_cmd vm-reboot uuid="$UUID" force=true ;;
            suspend) xe_cmd vm-suspend uuid="$UUID" ;;
            resume)  xe_cmd vm-resume uuid="$UUID" ;;
        esac
        # Redirecionar após ação
        echo "Status: 303 See Other"
        echo "Location: /cgi-bin/vm.sh"
        echo ""
        exit 0
    fi
fi

# HTML com estilo moderno
cat << HTML
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Gerenciador de VMs - XCP-ng</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: rgba(255,255,255,0.95);
            border-radius: 20px;
            box-shadow: 0 15px 35px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        header {
            background: linear-gradient(90deg, #1976d2, #2196f3);
            color: white;
            padding: 25px 30px;
            text-align: center;
        }
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 15px;
        }
        .stats-bar {
            background: #f5f7fa;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 15px;
            border-bottom: 2px solid #e0e0e0;
        }
        .stat-item {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.1em;
        }
        .stat-value {
            font-weight: bold;
            color: #1976d2;
        }
        .vm-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 25px;
            padding: 30px;
        }
        .vm-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            border-left: 5px solid;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .vm-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        .vm-card.running { border-color: #4caf50; }
        .vm-card.halted { border-color: #f44336; }
        .vm-card.suspended { border-color: #ff9800; }
        .vm-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #eee;
        }
        .vm-name {
            font-size: 1.3em;
            font-weight: 600;
            color: #2c3e50;
        }
        .vm-status {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
        }
        .status-running { background: #e8f5e9; color: #2e7d32; }
        .status-halted { background: #ffebee; color: #c62828; }
        .status-suspended { background: #fff3e0; color: #ef6c00; }
        .vm-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 20px;
        }
        .action-btn {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s;
        }
        .btn-start { background: #4caf50; color: white; }
        .btn-stop { background: #f44336; color: white; }
        .btn-reboot { background: #ff9800; color: white; }
        .btn-suspend { background: #9c27b0; color: white; }
        .btn-resume { background: #2196f3; color: white; }
        .action-btn:hover { opacity: 0.9; transform: scale(1.05); }
        .vm-uuid {
            font-family: monospace;
            font-size: 0.85em;
            color: #666;
            margin-top: 10px;
            word-break: break-all;
        }
        footer {
            text-align: center;
            padding: 25px;
            background: #f8f9fa;
            border-top: 1px solid #dee2e6;
            color: #666;
            font-size: 0.95em;
        }
        .refresh-info {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-top: 10px;
        }
        @media (max-width: 768px) {
            .vm-grid { grid-template-columns: 1fr; padding: 15px; }
            header h1 { font-size: 2em; }
            .stats-bar { flex-direction: column; align-items: flex-start; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1><i class="fas fa-server"></i> Gerenciador de VMs - XCP-ng</h1>
            <p>Controle centralizado de máquinas virtuais</p>
        </header>
        
        <div class="stats-bar" id="stats">
            <!-- Stats serão preenchidos por JavaScript -->
        </div>
        
        <div class="vm-grid" id="vm-list">
            <!-- VMs serão carregadas aqui -->
        </div>
        
        <footer>
            <p>Sistema atualizado em tempo real | Desenvolvido para XCP-ng</p>
            <div class="refresh-info">
                <i class="fas fa-sync-alt"></i>
                <span>Atualização automática a cada 30 segundos</span>
            </div>
        </footer>
    </div>
    
    <script>
    // Função para carregar VMs via AJAX
    async function loadVMs() {
        try {
            const response = await fetch('/cgi-bin/vm-data.sh');
            const data = await response.json();
            updateDisplay(data);
        } catch (error) {
            console.error('Erro ao carregar VMs:', error);
        }
    }
    
    // Atualizar display com dados
    function updateDisplay(data) {
        // Atualizar estatísticas
        document.getElementById('stats').innerHTML = \`
            <div class="stat-item">
                <i class="fas fa-server"></i>
                <span>Total: <span class="stat-value">\${data.total}</span> VMs</span>
            </div>
            <div class="stat-item">
                <i class="fas fa-play-circle" style="color:#4caf50"></i>
                <span>Rodando: <span class="stat-value">\${data.running}</span></span>
            </div>
            <div class="stat-item">
                <i class="fas fa-stop-circle" style="color:#f44336"></i>
                <span>Paradas: <span class="stat-value">\${data.halted}</span></span>
            </div>
            <div class="stat-item">
                <i class="fas fa-pause-circle" style="color:#ff9800"></i>
                <span>Suspensas: <span class="stat-value">\${data.suspended}</span></span>
            </div>
        \`;
        
        // Atualizar lista de VMs
        const vmList = document.getElementById('vm-list');
        vmList.innerHTML = data.vms.map(vm => \`
            <div class="vm-card \${vm.state}">
                <div class="vm-header">
                    <div class="vm-name">
                        <i class="fas fa-desktop"></i> \${vm.name}
                    </div>
                    <div class="vm-status status-\${vm.state}">
                        <i class="fas fa-circle"></i> \${vm.stateDisplay}
                    </div>
                </div>
                
                <div class="vm-actions">
                    \${getActionButtons(vm)}
                </div>
                
                <div class="vm-uuid">
                    <i class="fas fa-fingerprint"></i> \${vm.uuid}
                </div>
            </div>
        \`).join('');
    }
    
    // Gerar botões de ação baseado no estado
    function getActionButtons(vm) {
        const buttons = [];
        const forms = [];
        
        if (vm.state === 'running') {
            buttons.push(\`
                <button class="action-btn btn-stop" onclick="executeAction('\${vm.uuid}', 'stop')">
                    <i class="fas fa-power-off"></i> Parar
                </button>
                <button class="action-btn btn-reboot" onclick="executeAction('\${vm.uuid}', 'reboot')">
                    <i class="fas fa-redo"></i> Reiniciar
                </button>
                <button class="action-btn btn-suspend" onclick="executeAction('\${vm.uuid}', 'suspend')">
                    <i class="fas fa-pause"></i> Suspender
                </button>
            \`);
        } else if (vm.state === 'halted') {
            buttons.push(\`
                <button class="action-btn btn-start" onclick="executeAction('\${vm.uuid}', 'start')">
                    <i class="fas fa-play"></i> Iniciar
                </button>
            \`);
        } else if (vm.state === 'suspended') {
            buttons.push(\`
                <button class="action-btn btn-resume" onclick="executeAction('\${vm.uuid}', 'resume')">
                    <i class="fas fa-play"></i> Retomar
                </button>
                <button class="action-btn btn-start" onclick="executeAction('\${vm.uuid}', 'start')">
                    <i class="fas fa-power-off"></i> Ligar
                </button>
            \`);
        }
        
        return buttons.join('');
    }
    
    // Executar ação (POST)
    async function executeAction(uuid, action) {
        if (!confirm('Tem certeza que deseja executar esta ação?')) return;
        
        const formData = new FormData();
        formData.append('uuid', uuid);
        formData.append('action', action);
        
        try {
            await fetch('/cgi-bin/vm.sh', {
                method: 'POST',
                body: new URLSearchParams(formData)
            });
            // Recarregar após 1 segundo
            setTimeout(() => loadVMs(), 1000);
        } catch (error) {
            alert('Erro ao executar ação: ' + error.message);
        }
    }
    
    // Carregar VMs inicialmente e a cada 30 segundos
    loadVMs();
    setInterval(loadVMs, 30000);
    </script>
</body>
</html>
HTML
EOF
    
    # Criar script para gerar dados JSON (para AJAX)
    cat > "$CGI_DIR/vm-data.sh" << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""

XE_USER="root"
XE_PASS="91687008"
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

xe_cmd() {
    xe -u "$XE_USER" -pw "$XE_PASS" "$@" 2>/dev/null
}

# Contadores
total=0
running=0
halted=0
suspended=0
vms_json=""

# Obter lista de VMs
vm_list=$(xe_cmd vm-list is-control-domain=false is-a-template=false --minimal)

if [ -n "$vm_list" ]; then
    IFS=',' read -ra uuid_array <<< "$vm_list"
    
    for uuid in "${uuid_array[@]}"; do
        [ -z "$uuid" ] && continue
        
        name=$(xe_cmd vm-param-get uuid="$uuid" param-name=name-label)
        state=$(xe_cmd vm-param-get uuid="$uuid" param-name=power-state)
        
        # Traduzir estado para português
        case "$state" in
            "running")   stateDisplay="Rodando"; ((running++)) ;;
            "halted")    stateDisplay="Parada"; ((halted++)) ;;
            "suspended") stateDisplay="Suspensa"; ((suspended++)) ;;
            *)           stateDisplay="$state" ;;
        esac
        
        # Adicionar à lista JSON
        if [ -n "$vms_json" ]; then
            vms_json="$vms_json,"
        fi
        vms_json="$vms_json{\"uuid\":\"$uuid\",\"name\":\"$name\",\"state\":\"$state\",\"stateDisplay\":\"$stateDisplay\"}"
        
        ((total++))
    done
fi

# Gerar JSON de saída
cat << JSON
{
  "total": $total,
  "running": $running,
  "halted": $halted,
  "suspended": $suspended,
  "vms": [$vms_json],
  "timestamp": "$(date +'%Y-%m-%d %H:%M:%S')",
  "hostname": "$(hostname)"
}
JSON
EOF
    
    # Dar permissões de execução
    chmod +x "$CGI_DIR/vm.sh" "$CGI_DIR/vm-data.sh"
    
    # Criar página de saúde do serviço
    cat > "$CGI_DIR/health.sh" << 'EOF'
#!/bin/bash
echo "Content-Type: application/json"
echo ""
echo '{"status":"online","service":"webvm","timestamp":"'$(date -Iseconds)'"}'
EOF
    chmod +x "$CGI_DIR/health.sh"
    
    print_success "Interface web instalada em $WEB_DIR"
}

# ===== CONFIGURAR SYSTEMD SERVICE =====
configure_systemd_service() {
    print_step "Configurando serviço systemd"
    
    # Criar arquivo de serviço
    cat > /etc/systemd/system/webvm.service << EOF
[Unit]
Description=XCP-ng Web VM Manager
After=network.target xapi.service
Wants=network.target xapi.service
Requires=xapi.service

[Service]
Type=simple
User=root
WorkingDirectory=$WEB_DIR
ExecStart=/usr/bin/python3 -m http.server $PORT --cgi --bind 0.0.0.0 --directory $WEB_DIR
Restart=always
RestartSec=5
StandardOutput=append:$LOG_DIR/webvm.log
StandardError=append:$LOG_DIR/webvm-error.log
Environment=PYTHONUNBUFFERED=1
Nice=10
LimitNOFILE=4096

# Segurança
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$WEB_DIR $LOG_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    # Criar serviço de monitoramento
    cat > /etc/systemd/system/webvm-monitor.service << EOF
[Unit]
Description=WebVM Monitor - Verifica saúde do serviço
After=webvm.service
Requires=webvm.service

[Service]
Type=oneshot
User=root
ExecStart=/bin/bash -c 'curl -s -f http://localhost:$PORT/cgi-bin/health.sh > /dev/null || systemctl restart webvm'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    cat > /etc/systemd/system/webvm-monitor.timer << EOF
[Unit]
Description=Verifica saúde do WebVM a cada 5 minutos

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Recarregar systemd
    systemctl daemon-reload
    
    # Habilitar e iniciar serviços
    systemctl enable --now webvm.service
    systemctl enable --now webvm-monitor.timer
    
    print_success "Serviço systemd configurado"
}

# ===== CONFIGURAR FIREWALL =====
configure_firewall() {
    print_step "Configurando firewall"
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state >/dev/null 2>&1; then
            firewall-cmd --permanent --add-port=$PORT/tcp
            firewall-cmd --reload
            print_success "Porta $PORT aberta no firewall"
        else
            print_info "FirewallD não está rodando"
        fi
    elif command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
        print_info "Regra iptables adicionada (persistência requer configuração adicional)"
    else
        print_info "Nenhum firewall detectado, verificando portas"
    fi
}

# ===== CONFIGURAR CRON PARA MONITORAMENTO =====
configure_cron() {
    print_step "Configurando agendamento com cron"
    
    # Criar backup do crontab atual
    backup_file="/root/crontab_backup_$(date +%Y%m%d_%H%M%S)"
    crontab -l > "$backup_file" 2>/dev/null || true
    print_info "Backup do crontab salvo em: $backup_file"
    
    # Criar script de monitoramento
    cat > /root/check-webvm.sh << 'EOF'
#!/bin/bash
# Script de monitoramento do WebVM
PORT=8081
LOG="/var/log/webvm/monitor.log"

echo "$(date): Verificando serviço WebVM..." >> "$LOG"

# Verificar se o serviço está rodando
if ! systemctl is-active --quiet webvm.service; then
    echo "$(date): Serviço parado, reiniciando..." >> "$LOG"
    systemctl restart webvm.service
    echo "$(date): Serviço reiniciado" >> "$LOG"
fi

# Verificar se responde na porta
if ! timeout 5 curl -s -f "http://localhost:$PORT/cgi-bin/health.sh" >/dev/null; then
    echo "$(date): Porta $PORT não responde, reiniciando..." >> "$LOG"
    systemctl restart webvm.service
    echo "$(date): Serviço reiniciado após falha na porta" >> "$LOG"
fi

# Limpar logs antigos (manter últimos 30 dias)
find /var/log/webvm/ -name "*.log" -mtime +30 -delete
EOF
    
    chmod +x /root/check-webvm.sh
    
    # Adicionar ao crontab
    (
        crontab -l 2>/dev/null | grep -v "check-webvm.sh"
        echo ""
        echo "# ========================================="
        echo "# Monitoramento WebVM - XCP-ng"
        echo "# Configurado em: $(date)"
        echo "# ========================================="
        echo "# Verificar serviço a cada 30 minutos"
        echo "*/30 * * * * /root/check-webvm.sh >/dev/null 2>&1"
        echo ""
        echo "# Iniciar serviço após boot (aguardar 5 minutos para network/xapi)"
        echo "@reboot sleep 300 && systemctl start webvm.service"
        echo ""
        echo "# ========================================="
    ) | crontab -
    
    print_success "Cron configurado para verificar a cada 30 minutos"
}

# ===== CRIAR SCRIPT DE DESINSTALAÇÃO =====
create_uninstaller() {
    print_step "Criando script de desinstalação"
    
    cat > /root/uninstall-webvm.sh << 'EOF'
#!/bin/bash
# Script de desinstalação do WebVM Manager
# Uso: sudo ./uninstall-webvm.sh

set -e

echo "========================================"
echo "  DESINSTALANDO WEBVM MANAGER"
echo "========================================"

# Parar e desabilitar serviços
echo "[1/5] Parando serviços..."
systemctl stop webvm.service webvm-monitor.timer 2>/dev/null || true
systemctl disable webvm.service webvm-monitor.timer 2>/dev/null || true

# Remover arquivos de serviço
echo "[2/5] Removendo arquivos systemd..."
rm -f /etc/systemd/system/webvm.service
rm -f /etc/systemd/system/webvm-monitor.service
rm -f /etc/systemd/system/webvm-monitor.timer
systemctl daemon-reload

# Remover do crontab
echo "[3/5] Removendo agendamentos..."
crontab -l 2>/dev/null | grep -v "check-webvm.sh" | grep -v "webvm.service" | crontab -

# Remover arquivos e diretórios (opcional)
echo "[4/5] Remover arquivos? (s/n)"
read -r resposta
if [[ "$resposta" =~ ^[Ss]$ ]]; then
    echo "Removendo diretórios..."
    rm -rf /opt/webvm
    rm -rf /var/log/webvm
    rm -f /root/check-webvm.sh
    rm -f /root/uninstall-webvm.sh
    echo "Arquivos removidos."
else
    echo "Arquivos mantidos em:"
    echo "  /opt/webvm"
    echo "  /var/log/webvm"
    echo "  /root/check-webvm.sh"
fi

# Fechar porta no firewall
echo "[5/5] Configurando firewall..."
if command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state >/dev/null 2>&1; then
        firewall-cmd --permanent --remove-port=8081/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
fi

echo "========================================"
echo "  DESINSTALAÇÃO COMPLETA!"
echo "========================================"
echo ""
echo "Para remover completamente, reinicie o servidor."
EOF
    
    chmod +x /root/uninstall-webvm.sh
    print_success "Script de desinstalação criado: /root/uninstall-webvm.sh"
}

# ===== TESTAR INSTALAÇÃO =====
test_installation() {
    print_step "Testando instalação..."
    
    echo -e "\n${YELLOW}=== STATUS DOS SERVIÇOS ===${NC}"
    systemctl status webvm.service --no-pager -l
    
    echo -e "\n${YELLOW}=== VERIFICANDO TIMER ===${NC}"
    systemctl list-timers --all | grep webvm
    
    echo -e "\n${YELLOW}=== VERIFICANDO CRON ===${NC}"
    crontab -l | grep -A3 -B3 "check-webvm"
    
    echo -e "\n${YELLOW}=== TESTANDO CONEXÃO ===${NC}"
    sleep 3
    if curl -s -f "http://localhost:$PORT/cgi-bin/health.sh" >/dev/null; then
        print_success "Serviço respondendo na porta $PORT"
        
        # Obter IP
        IP=$(hostname -I | awk '{print $1}' || echo "localhost")
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}       INSTALAÇÃO COMPLETA!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${YELLOW}URL DE ACESSO:${NC}"
        echo -e "  http://$IP:$PORT"
        echo ""
        echo -e "${YELLOW}COMANDOS ÚTEIS:${NC}"
        echo -e "  Ver logs:        tail -f /var/log/webvm/webvm.log"
        echo -e "  Status serviço:  systemctl status webvm"
        echo -e "  Reiniciar:       systemctl restart webvm"
        echo -e "  Desinstalar:     /root/uninstall-webvm.sh"
        echo ""
        echo -e "${YELLOW}AGENDAMENTO:${NC}"
        echo -e "  • Inicia automaticamente no boot"
        echo -e "  • Verificação automática a cada 30 minutos"
        echo -e "  • Monitoramento a cada 5 minutos (systemd timer)"
        echo ""
    else
        print_error "Serviço não responde na porta $PORT"
        echo "Verifique os logs: journalctl -u webvm.service"
    fi
}

# ===== FUNÇÃO PRINCIPAL =====
main() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     WEB XCP-NG MANAGER - INSTALAÇÃO COMPLETA      ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Menu interativo
    echo "Este script irá instalar e configurar:"
    echo "1. Interface web para gerenciar VMs"
    echo "2. Serviço systemd com auto-inicialização"
    echo "3. Monitoramento automático (cron + systemd timer)"
    echo "4. Verificação periódica a cada 30 minutos"
    echo ""
    echo -e "${YELLOW}ATENÇÃO:${NC} A senha do XE será: $XE_PASS"
    echo ""
    
    read -p "Deseja continuar? (s/n): " -r resposta
    [[ ! "$resposta" =~ ^[Ss]$ ]] && { print_info "Instalação cancelada"; exit 0; }
    
    # Executar passos
    validate_prerequisites
    install_web_interface
    configure_systemd_service
    configure_firewall
    configure_cron
    create_uninstaller
    test_installation
    
    echo -e "\n${GREEN}✓ Instalação concluída com sucesso!${NC}"
}

# ===== EXECUTAR =====
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
