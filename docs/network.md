# 🌐 Network — DNS، پروکسی، و ابزارهای شبکه

## dnscrypt-proxy

رمزگذاری تمام DNS queries. دور زدن DNS poisoning.

```bash
# بررسی وضعیت
systemctl status dnscrypt-proxy

# تست DNS
doggo google.com               # جستجوی DNS مدرن
dig @127.0.0.1 google.com      # جستجوی کلاسیک
nslookup google.com            # جستجوی ساده

# بررسی اینکه DNS از dnscrypt-proxy استفاده می‌کند
resolvectl status              # باید 127.0.0.1 نشان دهد
```

**تنظیمات:**
- listen: `127.0.0.1:53`
- bootstrap: Quad9, Cloudflare, Google
- cache: 512 entries
- IPv6: غیرفعال

---

## v2raya

رابط وب برای مدیریت پروکسی.

```bash
# بررسی وضعیت
systemctl status v2raya

# باز کردن رابط وب
# مرورگر: http://127.0.0.1:2017
```

**تنظیمات:** پورت 2017، رابط وب محلی.

---

## ابزارهای شبکه

### doggo

جستجوی DNS مدرن.

```bash
doggo google.com                # جستجوی ساده
doggo google.com @1.1.1.1      # با سرور خاص
doggo -t AAAA google.com       # فقط IPv6
doggo -t MX google.com         # رکورد MX
```

### mtr

ترکیب `ping` و `traceroute`.

```bash
mtr google.com                  # نمایش تعاملی
mtr --report google.com        # گزارش یکبار
```

### gping

ping با نمودار گرافیکی.

```bash
gping google.com                # ping با گراف
gping 8.8.8.8 1.1.1.1          # مقایسه دو سرور
```

### trippy

traceroute مدرن با رابط TUI.

```bash
trippy google.com               # traceroute تعاملی
```

### nmap

اسکنر شبکه.

```bash
nmap 192.168.1.1                # اسکن یک host
nmap -sn 192.168.1.0/24        # اسکن شبکه (فقط discovery)
nmap -sV 192.168.1.1           # تشخیص نسخه سرویس‌ها
nmap --top-ports 100 192.168.1.1  # اسکن 100 پورت برتر
```

### tcpdump

اسنیفر پکت.

```bash
sudo tcpdump -i eth0            # ضبط ترافیک
sudo tcpdump -i any port 80    # فقط HTTP
sudo tcpdump -w capture.pcap   # ذخیره در فایل
sudo tcpdump -r capture.pcap   # خواندن از فایل
```

### iftop

نمایش مصرف پهنای باند به ازای اتصال.

```bash
sudo iftop                      # نمایش مصرف شبکه
sudo iftop -i eth0             # روی اینترفیس خاص
```

### nethogs

نمایش مصرف شبکه به ازای پردازش.

```bash
sudo nethogs                    # نمایش مصرف per-process
sudo nethogs eth0              # روی اینترفیس خاص
```

### iperf3

ベンچمارک شبکه.

```bash
# سرور
iperf3 -s

# کلاینت
iperf3 -c 192.168.1.1          # تست سرعت
iperf3 -c 192.168.1.1 -R      # reverse (دانلود)
iperf3 -c 192.168.1.1 -P 4    # 4 اتصال موازی
```

---

## ابزارهای پروکسی

### xray

پلتفرم پروکسی پیشرفته.

```bash
xray run -c config.json         # اجرا با کانفیگ
```

### sing-box

پلتفرم پروکسی مدرن.

```bash
sing-box run -c config.json     # اجرا با کانفیگ
```

### v2ray

پلتفرم پروکسی قدیمی.

```bash
v2ray run -c config.json        # اجرا با کانفیگ
```

### proxychains-ng

اجرای اپلیکیشن‌ها از طریق پروکسی.

```bash
proxychains4 curl api.example.com    # curl از طریق پروکسی
proxychains4 firefox                  # فایرفاکس از طریق پروکسی
```

### tor

کلاینت Tor.

```bash
tor                             # اجرای Tor
# SOCKS5 proxy روی 127.0.0.1:9050
```

---

## ابزارهای دانلود

### wget

دانلود فایل.

```bash
wget https://example.com/file.zip           # دانلود ساده
wget -c https://example.com/large.zip       # ادامه دانلود
wget -r https://example.com/dir/            # دانلود recursive
```

### aria2

دانلود چند-threaded.

```bash
aria2c https://example.com/file.zip                  # دانلود ساده
aria2c -x 16 -s 16 https://example.com/file.zip     # 16 اتصال
aria2c -i urls.txt                                   # دانلود از لیست
```

### axel

دانلود سبک و سریع.

```bash
axel https://example.com/file.zip           # دانلود ساده
axel -n 10 https://example.com/file.zip    # 10 اتصال
```

---

## ابزارهای عیب‌یابی

### curl

درخواست HTTP.

```bash
curl https://api.github.com                    # GET
curl -X POST -d '{"name":"amir"}' api.com     # POST
curl -I https://example.com                    # فقط headers
curl -v https://example.com                    # verbose
curl -o file.zip https://example.com/file.zip  # ذخیره در فایل
```

### net-tools

ابزارهای قدیمی شبکه.

```bash
ifconfig                          # اطلاعات اینترفیس‌ها
netstat -tuln                     # پورت‌های باز
netstat -i                        # آمار اینترفیس‌ها
```

### iproute2

ابزارهای مدرن شبکه.

```bash
ip addr                           # اطلاعات اینترفیس‌ها
ip route                          # جدول مسیریابی
ip link                           # وضعیت اینترفیس‌ها
ss -tuln                          # پورت‌های باز (جایگزین netstat)
```

### ethtool

اطلاعات اینترفیس Ethernet.

```bash
sudo ethtool eth0                 # اطلاعات اینترفیس
sudo ethtool -i eth0              # اطلاعات درایور
sudo ethtool -s eth0 speed 1000  # تنظیم سرعت
```
