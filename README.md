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
| `acc252e` | короткий SHA коммита апстрима, из которого собран образ |
| `2026.09.21` | дата сборки (UTC) |

Для фиксации версии используйте тег с SHA - он однозначно определяет код tproxy-server.
Тег с датой дополнительно фиксирует состояние базовых образов.

## Запуск

```bash
docker run -d --name tproxy-server \
  -v /path/to/config:/etc/tproxy-server \
  imilya/tproxy-server:latest
```

По умолчанию сервер читает `/etc/tproxy-server/config.json` и
`/etc/tproxy-server/profiles.json`.

## Обновление

Коммит апстрима зафиксирован в `ARG TPROXY_COMMIT` в [Dockerfile](Dockerfile).

Renovate ежедневно сверяет его с веткой `master` апстрима и при расхождении сам
обновляет строку в `main`. Пуш в `main` с изменением `Dockerfile` запускает сборку
и публикацию образа, так что новый коммит апстрима попадает в `latest` в тот же день.
Несколько коммитов, вышедших за сутки, собираются одной пачкой.

Дополнительно каждый четверг образ пересобирается по расписанию из того же коммита
апстрима — чтобы подхватить обновления базовых образов `golang` и `debian`.

## Лицензия

[MIT](LICENSE) - на содержимое этого репозитория. Лицензия самого tproxy-server
находится в его [апстрим-репозитории](https://github.com/telegramdesktop/tproxy-server).
