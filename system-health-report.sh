#!/bin/bash

# ============================================
# SUNUCU & KUBERNETES SAĞLIK RAPORU
# ============================================

GMAIL="volkancandemir87@gmail.com"
APP_PASSWORD="YOUR_GMAIL_APP_PASSWORD"
HOSTNAME=$(hostname)
DATE=$(date '+%d.%m.%Y %H:%M')

# --- VERİ TOPLAMA ---
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$(awk "BEGIN {printf \"%.1f\", ($RAM_USED/$RAM_TOTAL)*100}")
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
UPTIME=$(uptime -p)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
IP=$(hostname -I | awk '{print $1}')

# --- SERVİS KONTROL ---
check_service() {
    systemctl is-active "$1" 2>/dev/null
}

NGINX_STATUS=$(check_service nginx)
HAPROXY_STATUS=$(check_service haproxy)
KEEPALIVED_STATUS=$(check_service keepalived)
K3S_STATUS=$(check_service k3s)

service_badge() {
    if [ "$1" = "active" ]; then
        echo "<span style='background:#27ae60;color:white;padding:3px 10px;border-radius:12px;font-size:13px;'>✅ ÇALIŞIYOR</span>"
    else
        echo "<span style='background:#e74c3c;color:white;padding:3px 10px;border-radius:12px;font-size:13px;'>❌ DURDU</span>"
    fi
}

# --- KUBERNETES VERİLERİ ---
K3S_NODES=$(sudo kubectl get nodes 2>/dev/null | tail -n +2 | while read line; do
    NAME=$(echo $line | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $2}')
    ROLE=$(echo $line | awk '{print $3}')
    AGE=$(echo $line | awk '{print $5}')
    if [ "$STATUS" = "Ready" ]; then
        COLOR="#27ae60"
        ICON="✅"
    else
        COLOR="#e74c3c"
        ICON="❌"
    fi
    echo "<tr><td>$NAME</td><td><span style='color:$COLOR;font-weight:bold;'>$ICON $STATUS</span></td><td>$ROLE</td><td>$AGE</td></tr>"
done)

K3S_PODS=$(sudo kubectl get pods -A 2>/dev/null | tail -n +2 | while read line; do
    NS=$(echo $line | awk '{print $1}')
    NAME=$(echo $line | awk '{print $2}')
    READY=$(echo $line | awk '{print $3}')
    STATUS=$(echo $line | awk '{print $4}')
    RESTARTS=$(echo $line | awk '{print $5}')
    if [ "$STATUS" = "Running" ] || [ "$STATUS" = "Completed" ]; then
        COLOR="#27ae60"
        ICON="✅"
    else
        COLOR="#e74c3c"
        ICON="⚠️"
    fi
    echo "<tr><td>$NS</td><td>$NAME</td><td>$READY</td><td><span style='color:$COLOR;font-weight:bold;'>$ICON $STATUS</span></td><td>$RESTARTS</td></tr>"
done)

# --- HTML RAPOR ---
HTML=$(cat <<HTMLEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { font-family: Arial, sans-serif; background: #f0f2f5; margin: 0; padding: 20px; }
  .container { max-width: 900px; margin: auto; }
  .header { background: linear-gradient(135deg, #2c3e50, #3498db); color: white; padding: 25px; border-radius: 10px; margin-bottom: 20px; }
  .header h1 { margin: 0; font-size: 24px; }
  .header p { margin: 5px 0 0; opacity: 0.8; }
  .card { background: white; border-radius: 10px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
  .card h2 { margin-top: 0; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 8px; font-size: 16px; }
  .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; }
  .metric { background: #f8f9fa; border-radius: 8px; padding: 15px; text-align: center; }
  .metric .value { font-size: 28px; font-weight: bold; color: #2c3e50; }
  .metric .label { font-size: 12px; color: #7f8c8d; margin-top: 4px; }
  .service-row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid #ecf0f1; }
  .service-row:last-child { border-bottom: none; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { background: #2c3e50; color: white; padding: 10px; text-align: left; }
  td { padding: 8px 10px; border-bottom: 1px solid #ecf0f1; }
  tr:hover { background: #f8f9fa; }
  .footer { text-align: center; color: #95a5a6; font-size: 12px; margin-top: 20px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>🖥️ Sunucu & Kubernetes Sağlık Raporu</h1>
    <p>📍 $HOSTNAME ($IP) &nbsp;|&nbsp; 🕐 $DATE</p>
  </div>

  <div class="card">
    <h2>📊 Sistem Metrikleri</h2>
    <div class="grid">
      <div class="metric"><div class="value">%$CPU_USAGE</div><div class="label">CPU Kullanımı</div></div>
      <div class="metric"><div class="value">%$RAM_PERCENT</div><div class="label">RAM ($RAM_USED MB / $RAM_TOTAL MB)</div></div>
      <div class="metric"><div class="value">$DISK_USAGE</div><div class="label">Disk ($DISK_USED / $DISK_TOTAL)</div></div>
      <div class="metric"><div class="value" style="font-size:16px;">$UPTIME</div><div class="label">Uptime</div></div>
    </div>
    <p style="color:#7f8c8d;font-size:13px;margin-top:15px;">⚡ Load Average: $LOAD</p>
  </div>

  <div class="card">
    <h2>🔧 Servis Durumları</h2>
    <div class="service-row"><span>Nginx</span>$(service_badge $NGINX_STATUS)</div>
    <div class="service-row"><span>HAProxy</span>$(service_badge $HAPROXY_STATUS)</div>
    <div class="service-row"><span>Keepalived</span>$(service_badge $KEEPALIVED_STATUS)</div>
    <div class="service-row"><span>K3s</span>$(service_badge $K3S_STATUS)</div>
  </div>

  <div class="card">
    <h2>☸️ Kubernetes Node Durumu</h2>
    <table><tr><th>Node</th><th>Durum</th><th>Rol</th><th>Yaş</th></tr>
    $K3S_NODES
    </table>
  </div>

  <div class="card">
    <h2>📦 Kubernetes Pod Durumu</h2>
    <table><tr><th>Namespace</th><th>Pod Adı</th><th>Ready</th><th>Durum</th><th>Restart</th></tr>
    $K3S_PODS
    </table>
  </div>

  <div class="footer">Bu rapor otomatik olarak oluşturulmuştur. | $DATE</div>
</div>
</body>
</html>
HTMLEOF
)

# --- MAİL GÖNDER ---
python3 -c "
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

msg = MIMEMultipart('alternative')
msg['Subject'] = '🖥️ Sunucu Raporu - $(hostname) - $DATE'
msg['From'] = '$GMAIL'
msg['To'] = '$GMAIL'
msg.attach(MIMEText('''$HTML''', 'html'))

with smtplib.SMTP_SSL('smtp.gmail.com', 465) as s:
    s.login('$GMAIL', '$APP_PASSWORD')
    s.sendmail('$GMAIL', '$GMAIL', msg.as_string())
    print('Mail gönderildi!')
"
