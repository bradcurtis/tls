# tls

A small collection of PowerShell scripts & helper classes to manage email‑domain data, MX records, TLS checks, and CSV processing — built around a lightweight logger for easy automation.

## 🔎 Overview

This repo is designed to help you:

- Maintain a CSV of domains and their TLS / MX / Third‑party email provider status.
- Extract unique domains from CSVs or email aliases.
- Enrich domain data with information such as MX records, third‑party provider flags, and associated email aliases.
- Check whether a domain’s mail setup supports STARTTLS (via external web‑tool lookup).
- Log every operation cleanly using a singleton logger, facilitating automation and auditability.

It’s written in **pure PowerShell 5.1**, so it works out-of-the-box on Windows without needing external dependencies.

## 🚀 Features

- Read / write CSVs.
- Add or update columns (e.g. `MxRecord`, `ThirdParty`, `Email`).
- De‑duplicate alias lists and map them to domains.
- Class‑based design with a shared logger → modular, reusable, easy to extend.
- StartTLS checking for domains via web queries (simple, quick, not heavy dependencies).
- Designed to be used via a simple `main.ps1` orchestration script or imported into larger automation workflows.

## 📁 Repo Structure

```
tls/
├── logger.ps1
├── DomainExtractor.ps1
├── DomainMxUpdater.ps1
├── DomainTlsCsvWriter.ps1
├── TlsChecker.ps1
├── DomainEmailEnricher.ps1
├── main.ps1
├── app.properties
```

## 🧰 Requirements

- Windows PowerShell 5.1
- No external modules required
- Internet access required for DNS/TLS lookups

## ✅ Getting Started

```powershell
git clone https://github.com/bradcurtis/tls.git
cd tls
.\main.ps1
```

## 🤝 Contributing

PRs welcome. Future improvements include MX lookup caching, more provider detection, output export formats, and test coverage.

## 📄 License

Specify a license here if desired.
