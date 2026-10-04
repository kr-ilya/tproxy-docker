# tproxy-docker

Docker-образ для [telegramdesktop/tproxy-server](https://github.com/telegramdesktop/tproxy-server).


## Образ

https://hub.docker.com/r/imilya/tproxy-server

```bash
docker pull imilya/tproxy-server:latest
```

### Теги

| Тег | Что это |
| --- | --- |
| `latest` | последняя сборка |
| `src-c8adb8b` | короткий SHA коммита **апстрима**, из которого собран образ |
| `sha-e5073db` | короткий SHA коммита **этого** репозитория, которым собран образ |
| `2026.10.03` | дата сборки (UTC) |


## Конфигурация

Образ ожидает каталог `/etc/tproxy-server` с тремя файлами: `config.json`,
`profiles.json` и `token.key`. Ниже – минимальные рабочие примеры; полный список
параметров со всеми лимитами и таймаутами есть в
[config.example.json](https://github.com/telegramdesktop/tproxy-server/blob/master/config.example.json)
апстрима.

### config.json

Указывать нужно только то, у чего нет значения по умолчанию:

```json
{
  "public_hostname": "proxy.example.com",
  "listen": "127.0.0.1:8080",
  "admin_listen": "127.0.0.1:8081",
  "public_dir": "/srv/tproxy-site",
  "token_key_file": "/etc/tproxy-server/token.key",
  "profiles_file": "/etc/tproxy-server/profiles.json"
}
```

- `public_hostname` – внешнее имя, под которым сервер доступен. Строго
  в нижнем регистре, ASCII или IDNA A-label, без схемы, порта и пути.
- `listen` и `admin_listen` – **только численный loopback-адрес** и обязательно
  разные. Это определяет схему запуска, см. [Запуск](#запуск).
- Ровно одно из `public_dir` или `public_upstream`. Каталог из `public_dir` должен
  существовать и содержать `index.html`; `public_upstream` – это `http://` на
  loopback-адрес, тоже без пути.
- `token_key_file` и `profiles_file` – пути внутри контейнера.
- Неизвестные ключи приводят к ошибке запуска, опечатка в имени параметра молча
  не игнорируется.

Блоки `limits` и `timeouts` можно не задавать совсем – значения по умолчанию
совпадают с `config.example.json`.

### profiles.json

```json
{
  "profiles": [
    {
      "name": "default",
      "secret": "0123456789abcdef0123456789abcdef",
      "backend": "127.0.0.1:443",
      "carrier_mode": "https"
    }
  ]
}
```

- От 1 до 32 профилей, имена уникальные, длиной 1–64 символа.
- `secret` – 16 байт: 32 шестнадцатеричных символа либо base64url. Допустим
  MTProto-префикс `dd`, тогда это 34 символа. Сгенерировать:
  `openssl rand -hex 16`.
- `backend` – адрес MTProto-бэкенда, тоже только численный loopback.
- `carrier_mode` – `https` (по умолчанию), `https-lanes`, `websocket`
  или `websocket-lanes`.
- Необязательный блок `limits` переопределяет глобальные лимиты для профиля.

### token.key

Ровно 32 случайных байта, и этот файл должен сохраняться между перезапусками –
сервер его не создаёт:

```bash
openssl rand 32 > token.key
```

### Права на файлы

`profiles.json` и `token.key` не должны быть доступны группе и остальным, иначе
сервер откажется стартовать. В контейнере процесс работает под uid `10001`, поэтому
владельца на хосте нужно выставить соответственно:

```bash
chown 10001:10001 profiles.json token.key
chmod 600 profiles.json token.key
```

## Запуск

Поскольку `listen`, `admin_listen` и `backend` принимают только loopback-адреса,
опубликовать порты через `-p` нельзя – внутри своего сетевого пространства
контейнера на `127.0.0.1` извне не попасть. Сервер рассчитан на работу за
терминирующим TLS реверс-прокси, который обращается к нему по loopback, поэтому
сетевое пространство нужно разделить с этим прокси.

Простейший вариант – сеть хоста:

```bash
docker run -d --name tproxy-server \
  --network host \
  -v /path/to/config:/etc/tproxy-server:ro \
  -v /path/to/site:/srv/tproxy-site:ro \
  imilya/tproxy-server:latest
```

В docker compose то же самое достигается общим сетевым пространством с контейнером
прокси – `network_mode: "service:caddy"` у сервиса tproxy-server. Пример конфигурации
Caddy есть в каталоге [deploy](https://github.com/telegramdesktop/tproxy-server/tree/master/deploy)
апстрима.

Каталог `/srv/tproxy-site` монтируется только при использовании `public_dir`;
с `public_upstream` он не нужен.

## Обновление

Коммит апстрима зафиксирован в `ARG TPROXY_COMMIT` в [Dockerfile](Dockerfile).

Renovate ежедневно сверяет его с веткой `master` апстрима и при расхождении готовит
обновление строки. Сначала образ собирается в ветке Renovate без публикации: если
`go test ./...` внутри сборки падает, обновление в `main` не попадает. После успешной
проверки Renovate мерджит ветку сам, и пуш в `main` запускает сборку с публикацией –
новый коммит апстрима оказывается в `latest` в тот же день. Несколько коммитов,
вышедших за сутки, собираются одной пачкой.

Дополнительно каждый четверг образ пересобирается по расписанию из того же коммита
апстрима – чтобы подхватить обновления базовых образов `golang` и `debian`.

## Лицензия

[MIT](LICENSE) – на содержимое этого репозитория. Лицензия самого tproxy-server
находится в его [апстрим-репозитории](https://github.com/telegramdesktop/tproxy-server).
