# High Availability (HA) Kubernetes Cluster with Keepalived & HAProxy

Bu proje, iki adet Ubuntu sunucusu üzerinde çalışan, **Keepalived (Virtual IP)** ve **HAProxy (Load Balancer)** ile desteklenmiş, kesintisiz hizmet veren (High Availability) bir **Kubernetes (K3s)** mimarisini göstermektedir.

## 🏗️ Mimari Tasarım (Architecture)

Proje, tek bir hata noktasını (Single Point of Failure - SPOF) ortadan kaldırmayı hedefler. Sistem şu şekilde çalışır:

1.  **Keepalived (VIP - 192.168.217.150):** Ağda süzülen ortak bir giriş kapısıdır. Aktif/Pasif modda çalışır. Eğer Master sunucu çökerse, VIP saniyeler içinde Worker sunucuya devredilir (Failover) ve trafik kesilmez.
2.  **HAProxy (Load Balancer - Port 8080):** VIP üzerinden gelen istekleri karşılar ve K3s içindeki uygulamanın açık olduğu NodePort'lara (32000) **Round Robin** (sırayla) algoritmasıyla dağıtır.
3.  **K3s Kubernetes:** Kendi Ingress (Traefik) portlarıyla (80/443) çakışmayı önlemek için, test uygulaması (Apache httpd) K8s Service olarak özel bir NodePort (32000) üzerinden dışarı açılmıştır.

## 🛠️ Kullanılan Teknolojiler

*   **İşletim Sistemi:** Ubuntu Server 24.04 (Master ve Worker)
*   **Container Orchestration:** K3s (Lightweight Kubernetes)
*   **High Availability:** Keepalived
*   **Load Balancing / Reverse Proxy:** HAProxy
*   **Uygulama:** Apache (httpd:alpine imajı)

## ⚙️ Kurulum ve Ayar Dosyaları

Depoda bulunan yapılandırma dosyalarının görevleri şunlardır:

*   `keepalived-vip.conf`: MASTER ve BACKUP sunucuların, `192.168.217.150` sanal IP adresini kendi aralarında nasıl yöneteceklerini tanımlar.
*   `haproxy-loadbalancer.cfg`: 8080 portundan gelen HTTP isteklerinin, K3s Worker'larının 32000 portuna nasıl dağıtılacağını belirler. K3s default Traefik port çakışmalarını önlemek için frontend 8080'de çalışmaktadır.
*   `apache-deployment.yaml`: K3s içerisine 2 replikalı bir Apache web sunucusu (Pod) kurar ve bunu 32000 numaralı NodePort ile dış dünyaya servis eder.

## 🔥 Failover Test Senaryosu (Kaos Testi)

Bu mimarinin dayanıklılığı şu şekilde test edilmiştir:
1.  Tarayıcıdan `http://192.168.217.150:8080` adresine girildiğinde Apache'nin "It works!" sayfası başarıyla görüntülenir.
2.  Master sunucudaki Keepalived servisi bilerek durdurulur (`sudo systemctl stop keepalived`).
3.  Trafik anında Worker sunucuya geçer. Tarayıcı yenilendiğinde (F5) sayfa **kesintisiz** olarak gelmeye devam eder.

---
*Bu proje, DevOps öğrenim yolculuğumda altyapı, yük dengeleme, port yönetimi ve Kubernetes konularındaki pratik yetkinliklerimi sergilemek amacıyla hazırlanmıştır.*
