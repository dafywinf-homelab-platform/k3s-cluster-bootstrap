# K3s + MetalLB + Ingress Example

## Overview

This project demonstrates how to expose applications running in a **K3s** cluster (hosted on **Proxmox**) using **MetalLB** and **Ingress** (via Traefik). The design explains both a direct LoadBalancer approach and a more flexible Ingress-based setup using DNS wildcard services like `nip.io`.

---

## 🧱 Cluster Setup

- **Kubernetes Distribution**: [K3s](https://k3s.io) (lightweight Kubernetes)
- **Environment**: Local Proxmox VMs
- **Load Balancer**: [MetalLB](https://metallb.universe.tf)
- **Ingress Controller**: [Traefik](https://doc.traefik.io/traefik/) (default in K3s)

---

## ⚙️ How LoadBalancer Works with MetalLB

When a `Service` of type `LoadBalancer` is deployed:

1. **K3s** creates a service and requests an external IP.
2. **MetalLB** (running in Layer 2 mode) watches for this request.
3. MetalLB picks an IP from its configured pool and assigns it to the service.
4. MetalLB uses **ARP** to advertise the IP directly on the local network.
5. Traffic to that IP is routed to the backend pod(s) via kube-proxy.

This gives your service (e.g., NGINX hello world) a dedicated IP, accessible from your local network.

---

## 📦 Why Use Ingress Instead?

While `LoadBalancer` services are great for single apps, **Ingress** is more efficient and scalable in real-world setups.

### 🔁 Limitations of LoadBalancer:
- Each app requires a **separate external IP**
- No centralised routing logic
- Cannot easily support TLS, authentication, or custom rules

### ✅ Benefits of Ingress:
- One IP for **many services**
- **Path- or host-based routing** (e.g., `/app1`, `/app2`)
- **TLS termination** and cert management
- Integration with middlewares: auth, rate-limiting, etc.
- Cleaner, scalable application exposure

---

## 🌐 Using `nip.io` for Easy DNS

[`nip.io`](https://nip.io) is a wildcard DNS service that resolves domains like:

```

hello.192.168.86.10..nip.io

```

To:

```

192.168.86.10

````

This allows easy access to Ingress routes **without editing /etc/hosts or setting up a DNS server**.

---

## 🚀 Example: Hello World via Ingress

This repository includes:

- An `nginx`-based hello world app
- A `ClusterIP` service
- An `Ingress` resource that routes `http://hello.<ingress-ip>.nip.io` to the app

Replace `<ingress-ip>` with your Traefik/MetalLB external IP.

---

## 🔍 How to Find Your Ingress IP

1. List the Traefik service:

```bash
kubectl get svc -n kube-system
````

2. Look for the `EXTERNAL-IP` assigned by MetalLB:

```
traefik   LoadBalancer   10.43.0.5   192.168.86.10   80:80/TCP,443:443/TCP
```

3. Use that IP with `nip.io` to reach your app:

```
http://hello.192.168.86.10.nip.io
```

---

## 🧪 Next Steps

* Add HTTPS with cert-manager and Let's Encrypt
* Set up path-based routing for multiple services
* Apply auth middleware (Traefik supports basic auth)

---

## 📁 Files Included

* `hello-world.yaml`: Namespace, Deployment, Service, Ingress
* `README.md`: This documentation

---

## 🧠 Summary

| Feature             | LoadBalancer Only | Ingress (via Traefik)    |
| ------------------- | ----------------- | ------------------------ |
| External IP per app | ✅ Yes             | ❌ No (shared IP)         |
| Central routing     | ❌ No              | ✅ Yes                    |
| TLS support         | ❌ Manual          | ✅ Easy with cert-manager |
| Path/host routing   | ❌ No              | ✅ Yes                    |

---

## 🧠 Conclusion
For local dev clusters (like yours on Proxmox), **MetalLB + Traefik + nip.io** gives a near-production feel with minimal setup.
