# IndieForge

Журнал-каталог игр: инди, большие релизы, кооператив и MMO. Сайт живёт на
локальном Node.js-сервере, каталог и обращения хранятся в MariaDB, а интерфейс
собран на чистых HTML, CSS и JavaScript без сборщика.

## Что внутри

- 75 игр, 5 категорий и 49 жанров с длинными редакционными описаниями.
- Главная с витриной избранных игр, ручным слайдером и автопрокруткой.
- Поиск по названию, разработчику и жанру, фильтры по категориям и годам.
- Карточка игры: постер, широкий кадр, официальный трейлер, «паспорт игры»,
  системные требования и ссылки на Steam.
- Мастерская модов: 9 проектов, фильтры, поиск и заметка о сборке.
- Личный кабинет: профиль, аватар, фон-видео, избранное и обращения.
- Вход и регистрация, обратная связь с записью в MariaDB, советник.
- Админ-панель каталога и обращений.
- Тёплая журнальная тема: Fraunces + Manrope, бумажная палитра, прямые углы.

## Стек

| Слой | Технологии |
| --- | --- |
| Сервер | Node.js 20+ (проверено на 24.22), `http`, `zlib`, `mysql2` |
| База | MariaDB 13.0, InnoDB, `utf8mb4` |
| Клиент | HTML5, CSS3, ES5-совместимый JavaScript, без сборки |
| Видео | локальный `hls.js`, официальные Steam HLS-трейлеры |

## Быстрый старт

### 1. MariaDB

Установите MariaDB и импортируйте схему с данными:

```bash
mariadb -u root --default-character-set=utf8mb4 < database/indieforge.sql
```

В Windows:

```powershell
cmd /c '"C:\Program Files\MariaDB 13.0\bin\mariadb.exe" -u root --default-character-set=utf8mb4 < database\indieforge.sql'
```

Если MariaDB установлена, но не запущена:

```powershell
Start-Process "C:\Program Files\MariaDB 13.0\bin\mariadbd.exe" `
  -ArgumentList '--defaults-file="C:\Program Files\MariaDB 13.0\data\my.ini"','--console' `
  -WindowStyle Hidden
```

SQL создаёт базу `indieforge`, 13 таблиц, стартовые данные и пользователя
`indieforge` с паролем `indieforge2026`.

Для просмотра базы можно подключиться в HeidiSQL или DBeaver:
хост `127.0.0.1`, порт `3306`, пользователь `indieforge`, пароль
`indieforge2026`, база `indieforge`.

### 2. Зависимости и запуск

```bash
npm install
npm start
```

Сайт: <http://localhost:4173>
Проверка API: <http://localhost:4173/api/health>

Порт и параметры базы можно переопределить переменными окружения:

| Переменная | По умолчанию |
| --- | --- |
| `PORT` | `4173` |
| `DB_HOST` | `127.0.0.1` |
| `DB_PORT` | `3306` |
| `DB_USER` | `indieforge` |
| `DB_PASSWORD` | `indieforge2026` |
| `DB_NAME` | `indieforge` |
| `LOG_REQUESTS` | `0` (поставьте `1` для лога запросов) |

Пример для PowerShell:

```powershell
$env:PORT = "4173"
$env:DB_PASSWORD = "indieforge2026"
node server.js
```

## Тестовые доступы

| Роль | Логин | Пароль |
| --- | --- | --- |
| Пользователь | `demo` | `demo1234` |
| Администратор | `bruno` | `agent3310` |

Админ входит через `admin.html`. Сессия и избранное хранятся в `localStorage`
браузера, а каталог, моды и новые обращения — в MariaDB.

## Страницы

| Файл | Назначение |
| --- | --- |
| `index.html` | Главная: витрина, поиск, фильтры, каталог, советник |
| `game.html?id=...` | Карточка игры и трейлер |
| `mods.html` | Мастерская модов сообщества |
| `profile.html` | Профиль, избранное, обращения, фон профиля |
| `contacts.html` | Обратная связь с записью в базу |
| `login.html` | Вход и регистрация |
| `admin.html` | Админ-панель каталога и обращений |

## API

| Метод | Путь | Что делает |
| --- | --- | --- |
| `GET` | `/api/health` | Проверка сервера и MariaDB |
| `GET` | `/api/stats` | Количество игр, категорий, жанров, модов и обращений |
| `GET` | `/api/categories` | Категории и число игр в каждой |
| `GET` | `/api/games` | Игры; параметры `q`, `category`, `limit` |
| `GET` | `/api/games/:slug` | Игра, её трейлер и связанные моды |
| `GET` | `/api/mods` | Список модов |
| `POST` | `/api/feedback` | Новое обращение |

Пример обращения:

```bash
curl -X POST http://localhost:4173/api/feedback \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "{\"name\":\"Анна\",\"email\":\"anna@example.com\",\"topic\":\"Сайт\",\"message\":\"Хочу предложить игру для каталога.\"}"
```

## Производительность

- Brotli и gzip для HTML, CSS, JS, JSON и SVG, результат кэшируется в памяти.
- `ETag` и ответы `304 Not Modified`.
- Долгий `Cache-Control` для картинок, видео и vendor-файлов, неделя для CSS/JS.
- Поддержка `Range` для видео и больших файлов.
- Ленивая загрузка обложек и постеров, `fetchpriority="high"` для первого экрана.
- Локальные шрифты не требуются: используется Google Fonts с `display=swap`.
- Cache-busting через `?v=20261104f` у локальных CSS и JS.

## Структура

```
kysrach/
├── index.html
├── game.html
├── mods.html
├── profile.html
├── contacts.html
├── login.html
├── admin.html
├── server.js              — статика, сжатие, кэш и REST API
├── package.json
├── database/
│   └── indieforge.sql     — схема и данные MariaDB
└── assets/
    ├── css/
    │   ├── style.css      — базовые токены и старые компоненты
    │   ├── editorial.css  — журнальная тема всех страниц
    │   ├── home.css       — витрина и слайдер главной
    │   └── mods.css       — каталог модов
    ├── js/
    │   ├── data.js        — основной каталог игр
    │   ├── data-extra.js  — дополнительные игры и длинные описания
    │   ├── trailers.js    — официальные трейлеры Steam
    │   ├── store.js       — localStorage, сессия, избранное
    │   ├── common.js      — шапка, подвал, карточки, поиск
    │   ├── catalog.js     — фильтры и каталог
    │   ├── home.js        — слайдер главной
    │   ├── game.js        — карточка игры и плеер
    │   ├── mods.js        — мастерская модов
    │   ├── profile.js     — личный кабинет
    │   ├── contacts.js    — форма обратной связи
    │   ├── login.js       — вход и регистрация
    │   └── admin.js       — админ-панель
    ├── vendor/hls.min.js  — локальный HLS-плеер
    └── img/               — обложки, широкие кадры, аватары
```

## База данных

13 таблиц: `games`, `categories`, `game_categories`, `genres`,
`game_genres`, `trailers`, `mods`, `feedback`, `feedback_replies`, `users`,
`profiles`, `favorites`, `settings`.

Текущее наполнение:

| Таблица | Записей |
| --- | ---: |
| `games` | 75 |
| `categories` | 5 |
| `game_categories` | 134 |
| `genres` | 49 |
| `game_genres` | 301 |
| `trailers` | 75 |
| `mods` | 9 |
| `feedback` | 3 |
| `users` | 2 |

## Как это связано

- `assets/js/data.js` и `data-extra.js` — источник каталога для интерфейса.
- `database/indieforge.sql` — тот же каталог для API, статистики и админки.
- Форма обратной связи сохраняет обращение локально и отправляет его в
  `POST /api/feedback`; при недоступной базе локальная копия остаётся в браузере.
- Сессия, избранное, профиль и черновики админки живут в `localStorage`.
- Обложки и видео лежат локально в `assets/`; трейлеры подключаются с CDN Steam
  через HLS и откатываются на постер, если поток недоступен.

## Примечания

- Для корректной работы API и трейлеров открывайте сайт через сервер, а не
  файлом `index.html`.
- Если MariaDB не запущена, статика продолжит открываться, а API вернёт
  `503 database_unavailable`.
- Данные в `database/indieforge.sql` можно переимпортировать в любой момент:
  скрипт пересоздаёт таблицы и заново наполняет каталог.
