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

## ⚙️ Dosya Yapısı

k3s-ha-loadbalancer-project/
├── haproxy/
│ └── haproxy.cfg # HAProxy Round Robin config
├── keepalived/
│ └── keepalived-master.conf # VIP / VRRP yapılandırması
├── nginx/
│ ├── sunucu1-index.html # Mavi sayfa (Master)
│ └── sunucu2-index.html # Kırmızı sayfa (Worker)
├── kubernetes/
│ └── kubernetes.yaml # K3s Deployment + Service + Ingress
└── README.md


---

## 🔥 Kritik Sorun ve Çözüm: Port Savaşı

Bu projede karşılaşılan en önemli sorun **port çakışmasıydı.**

**Sorun:** K3s kurulduğunda otomatik olarak gelen **Traefik**, `LoadBalancer` tipiyle her iki sunucunun IP'sine port 80'i bağlamıştı. HAProxy da port 80 istiyordu. İki servis aynı kapıyı tutmaya çalışıyordu.

**Teşhis:**
```bash
sudo kubectl get svc -n kube-system | grep traefik
sudo ss -tlnp | grep :80
Çözüm: Traefik'i kubectl patch ile port 8888'e taşıdık:

bash
Copy
sudo kubectl patch svc traefik -n kube-system --type='json' \
  -p='[{"op":"replace","path":"/spec/ports/0/port","value":8888},
       {"op":"replace","path":"/spec/ports/1/port","value":8443}]'
Sonuç: Port 80 tamamen HAProxy'ye bırakıldı.

🎬 Failover Test Senaryosu
Tarayıcıdan http://192.168.217.150 aç → Mavi (Sunucu 1) veya Kırmızı (Sunucu 2) sayfa gelir
F5'e her basışta Round Robin devreye girer, sayfa değişir
Master'da Keepalived'ı durdur:
bash
Copy
sudo systemctl stop keepalived
VIP otomatik olarak Worker'a geçer, tarayıcı kesintisiz çalışmaya devam eder
Master'ı geri getir:
bash
Copy
sudo systemctl start keepalived
📦 Docker & Kubernetes
Speedtest uygulaması Docker ile build edilip Docker Hub'a push edildi:

bash
Copy
docker build -t myprecious1987/speedtest:v1 .
docker push myprecious1987/speedtest:v1
kubectl apply -f kubernetes/kubernetes.yaml
Uygulama speedtest namespace'inde çalışmaktadır:

bash
Copy
kubectl get pods -n speedtest
kubectl get svc -n speedtest
kubectl get ingress -n speedtest
