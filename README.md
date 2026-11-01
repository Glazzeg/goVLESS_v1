# goVLESS

Интерактивный установщик личного VLESS-сервера на базе 3X-UI и Xray. Поддерживаются режимы Reality (Lite) и TLS с собственным доменом (Pro).

## Быстрая установка на Ubuntu VPS

Подключитесь к серверу по SSH под `root` и запустите:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Glazzeg/goVLESS_v1/main/bootstrap.sh)
```

Установщик скачает проект из публичной ветки `main` и проведёт через настройку. Для Pro-режима потребуется домен, направленный на IP сервера. Перед установкой прочитайте [полную инструкцию](docs/DOCUMENTATION.md#2-установка-с-нуля) и [сведения о безопасности](docs/DOCUMENTATION.md#9-безопасность).

## Установка вручную

```bash
apt update && apt install -y git
git clone --depth 1 --branch main https://github.com/Glazzeg/goVLESS_v1.git /opt/govless-installer
cd /opt/govless-installer
bash govless.sh
```

## Документация

- [Полная документация](docs/DOCUMENTATION.md)
- [Лицензия](LICENSE)