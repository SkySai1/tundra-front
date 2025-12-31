# Tundra Front (форк Taiga Front)

Фронтенд приложения управления проектами Tundra, построенный на базе Taiga Front (AngularJS 1.x + CoffeeScript + Gulp).

Карта директорий и ключевых модулей проекта описана в `guide.md`.

## Быстрый старт

1. Установите Node.js `16.19.1` и npm `8.19.3` (через `nvm`, см. ниже).
2. Установите зависимости: `npm ci` (или `npm install`).
3. Запустите dev-режим: `npm start` и откройте `http://localhost:9001/`.

## Требования к окружению (важно)

Проект требует:

- Node.js: `16.19.1`
- npm: `8.19.3`

Это критично из‑за нативных зависимостей сборки (в частности `node-sass`): при несовпадении версии Node часто возникает ошибка вида `NODE_MODULE_VERSION ... was compiled against a different Node.js version`.

Проверка:

```bash
node -v
npm -v
```

## Установка nvm и переключение версии Node.js

### Linux / macOS (nvm)

1. Установите `nvm` (официальный способ — скрипт из репозитория nvm):

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
```

Если `curl` недоступен:

```bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
```

2. Перезагрузите терминал или подхватите `nvm` в текущей сессии (обычно достаточно):

```bash
export NVM_DIR="$HOME/.nvm"
test -s "$NVM_DIR/nvm.sh" && . "$NVM_DIR/nvm.sh"
```

3. Установите и активируйте нужную версию Node.js:

```bash
nvm install 16.19.1
nvm use 16.19.1
nvm alias default 16.19.1
```

4. Убедитесь, что npm нужной версии:

```bash
npm -v
```

Если версия отличается, зафиксируйте её:

```bash
npm i -g npm@8.19.3
```

### Windows

Для Windows используйте `nvm-windows`:

- https://github.com/coreybutler/nvm-windows

Далее:

```powershell
nvm install 16.19.1
nvm use 16.19.1
node -v
npm -v
```

## Установка зависимостей

Рекомендуемый вариант (строго по `package-lock.json`):

```bash
npm ci
```

Альтернатива:

```bash
npm install
```

Примечание: в `package.json` есть зависимости вида `git+ssh://git@github.com/...` (например Flot и плагины). Для установки может потребоваться доступ к GitHub по SSH и настроенные ключи (`ssh -T git@github.com`).

## Запуск и сборка

### Dev-режим (watch + локальный сервер)

```bash
npm start
```

Это запускает Gulp default task: сборку в `dist/`, поднятие Express на `http://localhost:9001/` и `watch` на изменения (см. `gulpfile.js`).

### Production-сборка (deploy)

```bash
npx gulp deploy
```

Артефакты попадают в `dist/` (версионированная папка вида `dist/v-<timestamp>/`).

## Конфигурация

Фронтенд читает настройки из `dist/conf.json`.

- Пример конфигурации: `conf/conf.example.json`
- При сборке Gulp копирует `conf/conf.example.json` в `dist/conf.json` (таск `conf` в `gulpfile.js`).

Для Docker используется шаблон `docker/conf.json.template`, который заполняется переменными окружения.

### Специфика форка Tundra

Добавлены параметры, влияющие на UI:

- `SUPPORT_URL` → заполняет `supportUrl` (ссылка на ресурс поддержки пользователей)
- `TUNDRA_INFO_BLOCK_ENABLED` → заполняет `infoBlockEnabled` (логический флаг, включает информационный блок «это форк»)

Точки использования в коде:

- `app/modules/navigation-bar/navigation-bar.directive.coffee`
- `app/modules/navigation-bar/dropdown-user/dropdown-user.directive.coffee`

## Структура проекта и ключевые модули

Полная карта директорий и примеры расширения функциональности — в `guide.md`.

Ниже — краткая «шпаргалка» по ключевым зонам:

### Корень репозитория

- `app/` — основной клиентский код (шаблоны Jade, CoffeeScript, стили, модули UI, локализации, ассеты).
- `app-loader/` — bootstrap/загрузчик приложения.
- `conf/` — пример и шаблоны конфигурации (`conf/conf.example.json`).
- `docker/` — сборка и запуск в контейнере (в т.ч. `docker/conf.json.template`).
- `e2e/` — e2e тесты и утилиты.
- `emojis/` — эмодзи-ассеты и индекс.
- `local-repo/` — локальные зависимости, подключаемые через `file:...`.
- `scripts/` — вспомогательные скрипты обслуживания проекта.
- `gulpfile.js` — сборка, dev server, watch, deploy.

### Работа с API (CoffeeScript слой)

Базовые компоненты интеграции с backend API:

- `$tgHttp` — HTTP-обертка над `$http` Angular с кешем и обработкой (`app/coffee/modules/base/http.coffee`).
- `$tgUrls` — генератор API-URL на основе конфигурации (`app/coffee/modules/base/urls.coffee`).
- `$tgRepo` — репозиторий CRUD/доступ к данным (`app/coffee/modules/base/repository.coffee`).
- `$tgResources` — агрегатор доменных ресурсов (`app/coffee/modules/resources.coffee`).
- `app/coffee/modules/resources/*.coffee` — ресурсные провайдеры по доменам (issues, tasks, wiki и т.д.).
- `app/modules/resources/*.service.coffee` — «новые» ресурсные сервисы для UI-модулей (поверх `urlsService`/http-клиента).

### UI-модули

Плагиноподобные UI-модули в `app/modules/` (attachments, navigation-bar, projects, wiki и др.). Они подключаются к основному приложению и обычно содержат:

- `*.module.coffee` — декларации модулей
- `*.directive.coffee` / `*.service.coffee` — директивы/сервисы
- `*.jade` / `*.scss` — шаблоны и стили
- `locales/` — локализации модулей

## Команды разработки

- Dev-режим: `npm start`
- Сборка (deploy): `npx gulp deploy`
- Линт scss: `npm run scss-lint`
- Unit-тесты: `npm test`
- E2E: `npm run e2e` (нужен запущенный backend)

## Документация

- Структура проекта и ключевые модули: `guide.md`
- Лицензия: `LICENSE`
- История изменений: `CHANGELOG.md`

## Лицензия

Код распространяется по лицензии AGPL-3.0-or-later — см. `LICENSE`.
