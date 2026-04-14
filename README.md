# 🚀 High Availability K3s Cluster — Keepalived + HAProxy + Nginx

Bu proje, iki Ubuntu sunucusu üzerinde kurulu, **Keepalived (VIP)** ve **HAProxy (Load Balancer)** ile desteklenmiş, kesintisiz hizmet veren (High Availability) bir **K3s Kubernetes** mimarisini göstermektedir.

DevOps öğrenim yolculuğumda Linux, Docker, Kubernetes, Nginx, HAProxy ve Keepalived konularındaki pratik yetkinliklerimi sergilemek amacıyla hazırlanmıştır.

---

## 🏗️ Mimari
Tarayıcı
│
▼
192.168.217.150 (Keepalived VIP — Floating IP)
│
▼
HAProxy (Port 80 — Round Robin Load Balancer)
│ │
▼ ▼
Nginx Nginx
Sunucu 1 Sunucu 2
(Port 8080) (Port 8080)
192.168.217.128 192.168.217.129
│
▼
K3s Kubernetes Cluster
(Master + Worker Node)
Traefik Ingress → Port 8888'e taşındı


---

## 🖥️ Sunucu Bilgileri

| Rol | Hostname | IP |
|-----|----------|----|
| Master (VRRP Primary) | kf-dr-prod-ms01 | 192.168.217.128 |
| Worker (VRRP Backup) | demircanvolkan | 192.168.217.129 |
| Virtual IP (VIP) | — | 192.168.217.150 |

---

## 🛠️ Kullanılan Teknolojiler

| Teknoloji | Görev |
|-----------|-------|
| Ubuntu Server 24.04 | İşletim Sistemi |
| K3s (Lightweight Kubernetes) | Container Orchestration |
| Docker + Docker Hub | Image build & registry |
| Keepalived | VIP / Failover yönetimi |
| HAProxy | Layer 7 Load Balancing |
| Nginx | Web sunucusu (Port 8080) |
| Traefik | K3s Ingress (Port 8888'e taşındı) |

---

## 📁 Klasör Yapısı

k3s-ha-loadbalancer-project/
├── haproxy/
│ ├── haproxy.cfg # HAProxy Round Robin config
│ └── haproxy-loadbalancer.cfg # HAProxy yapılandırması
├── keepalived/
│ ├── keepalived-master.conf # VIP / VRRP Master yapılandırması
│ └── keepalived-vip.conf # VIP tanımı
├── kubernetes/
│ └── kubernetes.yaml # K3s Deployment + Service + Ingress
├── nginx/
│ ├── sunucu1-index.html # Mavi sayfa (Master)
│ └── sunucu2-index.html # Kırmızı sayfa (Worker)
├── scripts/
│ └── system-health-report.sh # Sunucu & K8s sağlık raporu (Gmail SMTP)
└── README.md


---

## ⚙️ scripts/system-health-report.sh

Sunucu ve Kubernetes cluster sağlık durumunu toplayıp **görsel HTML rapor** olarak Gmail üzerinden e-posta gönderen Bash scriptidir.

**Topladığı Veriler:**
- CPU, RAM, Disk kullanımı
- Uptime ve Load Average
- Nginx, HAProxy, Keepalived, K3s servis durumları
- Kubernetes Node durumları
- Kubernetes Pod durumları (tüm namespace'ler)

**Crontab — 2 saatte bir otomatik çalışır:**
```bash
0 */2 * * * /home/volkancandemir/system-health-report.sh
Kullanım:

bash
Copy
chmod +x scripts/system-health-report.sh
# APP_PASSWORD değişkenine Gmail App Password gir
sudo ./scripts/system-health-report.sh
🔥 Kritik Sorun ve Çözüm: Port Savaşı
Sorun: K3s'in otomatik kurduğu Traefik, port 80'i tutuyordu. HAProxy da port 80 istiyordu.

Çözüm: Traefik port 8888'e taşındı:

bash
Copy
sudo kubectl patch svc traefik -n kube-system --type='json' \
  -p='[{"op":"replace","path":"/spec/ports/0/port","value":8888},
       {"op":"replace","path":"/spec/ports/1/port","value":8443}]'
🎬 Failover Test Senaryosu
http://192.168.217.150 → Mavi (Sunucu 1) veya Kırmızı (Sunucu 2) sayfa gelir
F5'e her basışta Round Robin devreye girer
Master'da Keepalived durdurulur → VIP Worker'a geçer → Kesintisiz çalışır
bash
Copy
sudo systemctl stop keepalived   # Failover tetikle
sudo systemctl start keepalived  # Geri getir
📦 Docker & Kubernetes
bash
Copy
docker build -t myprecious1987/speedtest:v1 .
docker push myprecious1987/speedtest:v1
kubectl apply -f kubernetes/kubernetes.yaml
kubectl get pods -n speedtest
