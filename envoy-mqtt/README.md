<p align="center">
  <img src="https://github.com/7290903/addon-repository/blob/main/envoy-mqtt/logo.png" alt="Envoy MQTT Failover by RunHouse" width="120" />
</p>

# Envoy MQTT Failover

**TCP-фейловер между несколькими MQTT-брокерами через Envoy Proxy**

Этот Home Assistant Add-on позволяет проксировать MQTT-соединения через Envoy Proxy и автоматически переключаться между брокерами при отказе.

---

## ⚙️ Возможности

- Надёжный TCP-фейловер для MQTT
- Автоматическое переключение между брокерами
- Установка пользовательского порта прослушивания
- Использование YAML-конфигурации `/config/envoy_mqtt.yaml`
- Поддержка архитектур: `amd64`, `armv7`, `armhf`, `aarch64`

---

## 🛠️ Настройка

### 1. Создайте конфигурационный файл `/config/envoy_mqtt.yaml`:

```yaml
port: 1885
brokers:
  - 192.168.2.48
  - 192.168.2.33
```

### 2. Настройте Home Assistant на подключение к прокси:

```yaml
mqtt:
  broker: 127.0.0.1
  port: 1885
```

> Убедитесь, что порт совпадает с указанным в `envoy_mqtt.yaml`.

---

## 🐋 Docker и структура

- Базовый образ: `envoyproxy/envoy:v1.29-latest`
- Точка входа: `run.sh`, который динамически генерирует `envoy.yaml`
- Система логирования: `stdout`, Envoy запускается с `--log-level info`

---

## 🔧 Параметры

- `port` — Порт, на котором Envoy слушает входящие подключения MQTT
- `brokers` — Список IP MQTT-брокеров (в порядке приоритетности)

---

## ✅ Проверка

- `docker logs <container>` — Проверка логов генерации и запуска
- `/tmp/envoy.yaml` — Сгенерированный файл конфигурации
- Admin API Envoy (опционально): `http://localhost:9901`

---

## 📦 Поддержка

Если вы столкнулись с проблемами:
1. Проверьте наличие `/config/envoy_mqtt.yaml`
2. Убедитесь, что порты открыты и брокеры доступны
3. Проверяйте логи `run.sh` и Envoy

---

**Автор**: [RunHouse Project]
