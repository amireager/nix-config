# 🌐 شبکه — DNS، پروکسی، و ابزارها

## dnscrypt-proxy

رمزگذاری تمام DNS queries. دور زدن DNS poisoning.

```bash
# بررسی وضعیت
systemctl status dnscrypt-proxy

# تست DNS
doggo google.com               # جستجوی DNS مدرن
dig @127.0.0.1 google.com      # جستجوی کلاسیک
```

**تنظیمات:**
- listen: `127.0.0.1:53`
- bootstrap: Quad9, Cloudflare
- cache: 512 entries
- IPv6: غیرفعال

---

## v2raya

رابط وب برای مدیریت پروکسی.

```bash
systemctl status v2raya         # بررسی وضعیت
# مرورگر: http://127.0.0.1:2017
```

---

## فایروال

فایروال فقط پورت‌های ضروری باز هست:

| پورت | پروتکل | کاربرد |
|---|---|---|
| 53 | TCP/UDP | DNS (dnscrypt-proxy) |

---

## ابزارهای شبکه (نصب‌شده)

### اساسی (روزانه)

| ابزار | کاربرد | مثال |
|---|---|---|
| **curl** | درخواست HTTP | `curl api.github.com` |
| **wget** | دانلود فایل | `wget url` |
| **dnsutils** | dig, nslookup | `dig @127.0.0.1 google.com` |
| **mtr** | ping + traceroute | `mtr google.com` |
| **nethogs** | مصرف شبکه per-process | `sudo nethogs` |
| **tcpdump** | ضبط پکت | `sudo tcpdump -i any` |
| **iproute2** | ip, ss | `ip addr`, `ss -tuln` |
| **sing-box** | پروکسی مدرن | `sing-box run -c config.json` |
| **xh** | HTTP client مدرن | `xh GET api.example.com` |

### تخصصی

| ابزار | کاربرد | مثال |
|---|---|---|
| **nmap** | اسکن شبکه | `nmap -sn 192.168.1.0/24` |
| **net-tools** | ifconfig (قدیمی) | `ifconfig` |
| **aria2** | دانلود multi-thread | `aria2c -x 16 url` |

---

## ابزارهای پروکسی (کامنت‌شده)

این ابزارها در فایل کانفیگ کامنت هستند. در صورت نیاز uncomment کنید:

| ابزار | کاربرد |
|---|---|
| **v2ray** | V2Ray core |
| **xray** | Xray core |
| **shadowsocks-libev** | Shadowsocks client |
| **tor** | Tor client |
| **proxychains-ng** | مسیردهی اپلیکیشن‌ها از طریق پروکسی |

---

## دستورات مفید

```bash
# تست اتصال
ping -c 4 8.8.8.8
mtr google.com

# بررسی DNS
doggo google.com
dig @127.0.0.1 google.com

# بررسی پورت‌ها
ss -tuln                    # پورت‌های باز
sudo tcpdump -i any port 80 # ترافیک HTTP

# مصرف شبکه
sudo nethogs                # per-process
sudo bandwhich              # per-process با جزئیات

# درخواست HTTP
curl -I https://example.com # فقط headers
xh GET api.github.com       # مدرن و رنگی
```
