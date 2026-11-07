
 Импорт: mariadb -u root --default-character-set=utf8mb4 < database/indieforge.sql

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS indieforge
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE indieforge;

DROP TABLE IF EXISTS feedback_replies;
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS trailers;
DROP TABLE IF EXISTS mods;
DROP TABLE IF EXISTS game_genres;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS game_categories;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS profiles;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS settings;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  email VARCHAR(190) NOT NULL DEFAULT '',
  password_hash VARCHAR(64) NOT NULL,
  role ENUM('member', 'admin') NOT NULL DEFAULT 'member',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_username (username),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE profiles (
  user_id INT UNSIGNED NOT NULL,
  bio VARCHAR(280) NOT NULL DEFAULT '',
  avatar_url VARCHAR(255) NOT NULL DEFAULT '',
  video_url VARCHAR(255) NOT NULL DEFAULT '',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE games (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(80) NOT NULL,
  title VARCHAR(160) NOT NULL,
  year SMALLINT UNSIGNED DEFAULT NULL,
  release_date VARCHAR(32) NOT NULL DEFAULT '',
  developer VARCHAR(160) NOT NULL DEFAULT '',
  publisher VARCHAR(160) NOT NULL DEFAULT '',
  website VARCHAR(255) NOT NULL DEFAULT '',
  rating DECIMAL(3,1) DEFAULT NULL,
  steam_score VARCHAR(24) NOT NULL DEFAULT '',
  weight ENUM('indie', 'aaa', 'mmo', 'next') NOT NULL DEFAULT 'indie',
  tagline VARCHAR(255) NOT NULL DEFAULT '',
  description MEDIUMTEXT NOT NULL,
  cover_path VARCHAR(255) NOT NULL DEFAULT '',
  wide_path VARCHAR(255) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_games_slug (slug),
  KEY idx_games_year (year),
  KEY idx_games_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(64) NOT NULL,
  title VARCHAR(64) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categories_slug (slug),
  UNIQUE KEY uq_categories_title (title)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_categories (
  game_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (game_id, category_id),
  CONSTRAINT fk_gc_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE,
  CONSTRAINT fk_gc_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE genres (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(64) NOT NULL,
  name VARCHAR(64) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_genres_slug (slug),
  UNIQUE KEY uq_genres_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE game_genres (
  game_id INT UNSIGNED NOT NULL,
  genre_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (game_id, genre_id),
  CONSTRAINT fk_gg_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE,
  CONSTRAINT fk_gg_genre FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE trailers (
  game_id INT UNSIGNED NOT NULL,
  name VARCHAR(190) NOT NULL DEFAULT '',
  hls_url VARCHAR(500) NOT NULL,
  poster_url VARCHAR(500) NOT NULL DEFAULT '',
  PRIMARY KEY (game_id),
  CONSTRAINT fk_trailers_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE favorites (
  user_id INT UNSIGNED NOT NULL,
  game_id INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, game_id),
  CONSTRAINT fk_favorites_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_favorites_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE feedback (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED DEFAULT NULL,
  name VARCHAR(120) NOT NULL DEFAULT '',
  email VARCHAR(190) NOT NULL DEFAULT '',
  phone VARCHAR(40) NOT NULL DEFAULT '',
  contact VARCHAR(190) NOT NULL DEFAULT '',
  topic VARCHAR(64) NOT NULL DEFAULT 'Вопрос',
  message TEXT NOT NULL,
  status ENUM('new', 'answered', 'closed') NOT NULL DEFAULT 'new',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  answered_at DATETIME DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_feedback_status (status),
  KEY idx_feedback_user (user_id),
  CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE feedback_replies (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  feedback_id INT UNSIGNED NOT NULL,
  author VARCHAR(120) NOT NULL DEFAULT 'IndieForge',
  body TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_replies_feedback (feedback_id),
  CONSTRAINT fk_replies_feedback FOREIGN KEY (feedback_id) REFERENCES feedback (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE mods (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(80) NOT NULL,
  title VARCHAR(190) NOT NULL,
  game_id INT UNSIGNED DEFAULT NULL,
  game_title VARCHAR(160) NOT NULL DEFAULT '',
  kicker VARCHAR(160) NOT NULL DEFAULT '',
  summary TEXT NOT NULL,
  body MEDIUMTEXT NOT NULL,
  engine VARCHAR(120) NOT NULL DEFAULT '',
  route VARCHAR(190) NOT NULL DEFAULT '',
  tools VARCHAR(190) NOT NULL DEFAULT '',
  status ENUM('ready', 'progress', 'testing') NOT NULL DEFAULT 'progress',
  status_label VARCHAR(32) NOT NULL DEFAULT '',
  version VARCHAR(32) NOT NULL DEFAULT '',
  compatibility VARCHAR(190) NOT NULL DEFAULT '',
  notes TEXT NOT NULL,
  cover_path VARCHAR(255) NOT NULL DEFAULT '',
  updated_label VARCHAR(64) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_mods_slug (slug),
  KEY idx_mods_status (status),
  CONSTRAINT fk_mods_game FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE settings (
  setting_key VARCHAR(80) NOT NULL,
  setting_value TEXT NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO users (id, username, email, password_hash, role, created_at) VALUES
  (1, 'demo', 'demo@indieforge.local', SHA2('demo1234', 256), 'member', NOW() - INTERVAL 40 DAY),
  (2, 'bruno', 'bruno@indieforge.local', SHA2('agent3310', 256), 'admin', NOW() - INTERVAL 180 DAY);

INSERT INTO profiles (user_id, bio) VALUES
  (1, 'Собираю игры, в которые хочется возвращаться. Люблю кооператив, медленные хорроры и длинные титры.'),
  (2, 'Редактор IndieForge. Читаю описания, проверяю моды и спорю с советником о том, что считать инди.');

INSERT INTO categories (id, slug, title) VALUES
  (1, 'syuzhetnye', 'Сюжетные'), (2, 'vyzhivaniya', 'Выживания'), (3, 'kooperativ', 'Кооператив'),
  (4, 'mmo', 'MMO'), (5, 'shuter', 'Шутер');

INSERT INTO games (id, slug, title, year, release_date, developer, publisher, website, rating, steam_score, weight, tagline, description, cover_path, wide_path) VALUES
  (
    1, 'sara', 'Sara', 2025, '2025', 'Independent studio', 'Independent studio',
    'https://store.steampowered.com/app/3576940/', '8.4', '89/100', 'indie',
    'Психологический хоррор о памяти, которая не хочет отпускать.',
    'Психологический хоррор о памяти, которая не хочет отпускать.\n\nSara — атмосферный хоррор от '
    'первого лица. Героиня просыпается в незнакомом месте и пытается собрать по кусочкам '
    'воспоминания, пока за ней наблюдает нечто, носящее её собственное лицо.\n\nSara не пытается '
    'напугать громкими скримерами. Она медленно расшатывает ощущение реальности: знакомые комнаты '
    'меняются, голоса звучат неправильно, а собственное отражение начинает жить отдельной жизнью. '
    'Чем ближе финал, тем меньше уверенности, что героиня вообще хочет вспомнить правду.\n\n'
    'Маленький, но очень уверенный психологический опыт.',
    'assets/img/games/sara.jpg', 'assets/img/games/wide/sara.jpg'
  ),
  (
    2, 'project-zomboid', 'Project Zomboid', 2013, '08.11.2013', 'The Indie Stone', 'The Indie Stone',
    'https://store.steampowered.com/app/108600/', '9.1', '95/100', 'indie',
    'Выживание, в котором смерть окончательна.',
    'Выживание, в котором смерть окончательна.\n\nИзометрический симулятор зомби-апокалипсиса: '
    'стройте укрытие, добывайте еду, лечите раны и проживите ещё один день в Ноксе. Мир живёт своей '
    'жизнью и не делает скидок.\n\nProject Zomboid не про победу над зомби — она про то, как долго '
    'вы сможете оставаться собой. Вы учитесь готовить, лечить раны, экономить электричество и '
    'понимать, что смерть здесь действительно окончательная. Именно поэтому каждый прожитый день '
    'имеет вес.\n\nЭталон жанра, который всё ещё развивается.',
    'assets/img/games/project-zomboid.jpg', 'assets/img/games/wide/project-zomboid.jpg'
  ),
  (
    3, 'warframe', 'Warframe', 2013, '25.03.2013', 'Digital Extremes', 'Digital Extremes',
    'https://store.steampowered.com/app/230410/', '8.6', '88/100', 'mmo', 'Космические ниндзя снова в деле.',
    'Космические ниндзя снова в деле.\n\nКооперативный экшен про тэнно — древних воинов в '
    'биомеханических костюмах. Быстрые миссии, сотни видов оружия и бесконечная прокачка в компании '
    'друзей.\n\nWarframe начинается как быстрый космический экшен, а через десяток часов оказывается '
    'большой историей о памяти, долге и свободе. Между миссиями вы возвращаетесь на корабль, '
    'слушаете радио и постепенно понимаете, кто такие тэнно на самом деле.\n\nЩедрая, странная и '
    'очень живая игра, которая не боится меняться.',
    'assets/img/games/warframe.jpg', 'assets/img/games/wide/warframe.jpg'
  ),
  (
    4, 'this-war-of-mine', 'This War of Mine', 2014, '14.11.2014', '11 bit studios', '11 bit studios',
    'https://store.steampowered.com/app/282070/', '9.0', '94/100', 'indie', 'Война — не только для солдат.',
    'Война — не только для солдат.\n\nСимулятор выживания группы гражданских в осаждённом городе. '
    'Днём вы прячетесь, ночью ищете припасы и принимаете решения, за которые потом будет стыдно или '
    'страшно.\n\nThis War of Mine не даёт вам стать героем. Вы просто пытаетесь сохранить жизнь '
    'нескольким людям в городе, где закончилось всё, кроме страха. Каждое решение — еда, лекарство, '
    'чужая квартира — остаётся с вами до финала.\n\nОдна из самых человечных игр о войне.',
    'assets/img/games/this-war-of-mine.jpg', 'assets/img/games/wide/this-war-of-mine.jpg'
  ),
  (
    5, 'eso', 'The Elder Scrolls Online', 2014, '04.04.2014', 'ZeniMax Online Studios', 'Bethesda Softworks',
    'https://store.steampowered.com/app/306130/', '8.2', '86/100', 'mmo', 'Тамриэль без границ.',
    'Тамриэль без границ.\n\nMMO в мире The Elder Scrolls: исследуйте провинции, вступайте в альянсы '
    'и проходите сюжетные линии в одиночку или с группой. Боевая система сочетает классические '
    'классы и свободное использование оружия.\n\nThe Elder Scrolls Online позволяет пройти сотни '
    'часов в одиночку, как обычную RPG, и только потом вспомнить, что вокруг живые люди. Провинции '
    'Тамриэля сделаны с уважением к лору, а гибкая система классов оставляет место экспериментам.\n\n'
    'Самый большой Тамриэль — и самый доступный.',
    'assets/img/games/eso.jpg', 'assets/img/games/wide/eso.jpg'
  ),
  (
    6, 'witcher3', 'The Witcher 3: Wild Hunt', 2015, '19.05.2015', 'CD Projekt Red', 'CD Projekt',
    'https://store.steampowered.com/app/292030/', '9.8', '98/100', 'aaa', 'Охота на чудовищ и на себя.',
    'Охота на чудовищ и на себя.\n\nГеральт ищет Цири по охваченным войной землям. Огромный открытый '
    'мир, моральные развилки и лучшие побочные квесты в жанре — всё ещё эталон.\n\nThe Witcher 3 '
    'держится не на размере карты, а на людях. Каждый контракт — маленькая история о страхе, '
    'жадности или любви. Геральт остаётся наблюдателем, но игрок постоянно решает, кому здесь можно '
    'верить.\n\nЭталон сюжетной RPG, который всё ещё держит планку.',
    'assets/img/games/witcher3.jpg', 'assets/img/games/wide/witcher3.jpg'
  ),
  (
    7, 'dying-light', 'Dying Light', 2015, '27.01.2015', 'Techland', 'Techland',
    'https://store.steampowered.com/app/239140/', '8.5', '93/100', 'aaa', 'Паркур против зомби.',
    'Паркур против зомби.\n\nХарран закрыт на карантин. Днём вы собираете припасы и помогаете '
    'выжившим, ночью выходите только с фонарём — и бежите. Кооператив на четверых усиливает панику в '
    'лучшем смысле.\n\nDying Light работает на контрасте: днём вы почти турист, ночью — добыча. '
    'Паркур превращает город в вертикальную площадку, а кооператив делает каждый побег немного '
    'смешнее и намного громче.\n\nОдна из лучших зомби-игр для кооператива.',
    'assets/img/games/dying-light.jpg', 'assets/img/games/wide/dying-light.jpg'
  ),
  (
    8, 'stardew', 'Stardew Valley', 2016, '26.02.2016', 'ConcernedApe', 'ConcernedApe',
    'https://store.steampowered.com/app/413150/', '9.4', '98/100', 'indie', 'Тихая жизнь, которая затягивает.',
    'Тихая жизнь, которая затягивает.\n\nВы унаследовали дедовскую ферму. Сажайте, ловите рыбу, '
    'дружите с городом и постепенно раскрывайте его секреты — в одиночку или с тремя друзьями.\n\n'
    'Stardew Valley начинается как история про побег из офиса, а превращается в маленький мир, где у '
    'каждого жителя есть привычки, обиды и мечты. Вы можете годами не трогать сюжет — и всё равно '
    'будете заняты.\n\nТерапия в виде игры, которая не надоедает.',
    'assets/img/games/stardew.jpg', 'assets/img/games/wide/stardew.jpg'
  ),
  (
    9, 'doom', 'DOOM', 2016, '13.05.2016', 'id Software', 'Bethesda Softworks',
    'https://store.steampowered.com/app/379720/', '9.1', '93/100', 'aaa', 'Рип и тир.',
    'Рип и тир.\n\nБыстрый шутер, в котором нет укрытий и перезарядки: только вы, демоны и дробовик. '
    'Ад на Марсе встречает металлом и кровищей.\n\nDOOM 2016 не тратит время на оправдания. Вы '
    'просыпаетесь, берёте дробовик и идёте вперёд. Но за простотой скрывается очень точный дизайн '
    'арен, где движение и агрессия — единственный способ выжить.\n\nВозрождение классики, которое до '
    'сих пор задаёт стандарт.',
    'assets/img/games/doom.jpg', 'assets/img/games/wide/doom.jpg'
  ),
  (
    10, 'black-desert', 'Black Desert', 2016, '17.03.2016', 'Pearl Abyss', 'Pearl Abyss',
    'https://store.steampowered.com/app/582660/', '7.9', '77/100', 'mmo', 'Красивая MMO с глубокой боевкой.',
    'Красивая MMO с глубокой боевкой.\n\nПесочница с открытым миром, нод-войнами и одной из самых '
    'зрелищных боевых систем в жанре. Можно жить торговлей, рыбалкой или осадой замков.\n\nBlack '
    'Desert — это в первую очередь ощущение движения. Боевая система настолько быстрая, что бой с '
    'обычным мобом превращается в танец. Всё остальное — торговля, узлы, осады — надстраивается '
    'вокруг этого удовольствия.\n\nКрасивая MMO, которая требует времени и терпения.',
    'assets/img/games/black-desert.jpg', 'assets/img/games/wide/black-desert.jpg'
  ),
  (
    11, 'hollow-knight', 'Hollow Knight', 2017, '24.02.2017', 'Team Cherry', 'Team Cherry',
    'https://store.steampowered.com/app/367520/', '9.5', '97/100', 'indie', 'Метроидвания о маленьком рыцаре.',
    'Метроидвания о маленьком рыцаре.\n\nХаллоунест полон жуков, тайн и очень недружелюбных существ. '
    'Исследуйте подземелья, улучшайте гвоздь и слушайте, как город шепчет свои истории.\n\nHollow '
    'Knight рассказывает историю королевства не через катсцены, а через пустые залы, обрывки '
    'надписей и то, как вы сами соединяете точки. Чем больше вы исследуете, тем печальнее становится '
    'картина.\n\nСовременная классика жанра.',
    'assets/img/games/hollow-knight.jpg', 'assets/img/games/wide/hollow-knight.jpg'
  ),
  (
    12, 'ark', 'ARK: Survival Evolved', 2017, '29.08.2017', 'Studio Wildcard', 'Studio Wildcard',
    'https://store.steampowered.com/app/346110/', '7.6', '82/100', 'mmo', 'Динозавры, крафт и немного хаоса.',
    'Динозавры, крафт и немного хаоса.\n\nВыживание на острове с динозаврами: приручайте зверей, '
    'стройте базы и защищайте их от других игроков. Кооператив и PvP здесь одинаково беспощадны.\n\n'
    'ARK — это игра про первое утро на пляже, когда вы не понимаете ничего. Потом появляются '
    'динозавры, базы и соседи, которые хотят всё это забрать. Выживание здесь социальное, даже когда '
    'вы играете соло.\n\nХаотичная, но незабываемая песочница.',
    'assets/img/games/ark.jpg', 'assets/img/games/wide/ark.jpg'
  ),
  (
    13, 'rdr2', 'Red Dead Redemption 2', 2018, '26.10.2018', 'Rockstar Games', 'Rockstar Games',
    'https://store.steampowered.com/app/1174180/', '9.7', '93/100', 'aaa', 'Последний вестерн Рокстара.',
    'Последний вестерн Рокстара.\n\nАртур Морган и банда Ван дер Линде пытаются выжить на закате '
    'Дикого Запада. Медленный, внимательный мир, в котором каждая поездка верхом — отдельная '
    'история.\n\nRed Dead Redemption 2 — история о людях, которые опоздали на собственную эпоху. '
    'Артур Морган не пытается стать хорошим; он просто начинает замечать, кого оставляет после себя. '
    'Именно это делает финал таким сильным.\n\nОдна из самых амбициозных игр ever made.',
    'assets/img/games/rdr2.jpg', 'assets/img/games/wide/rdr2.jpg'
  ),
  (
    14, 'mhw', 'Monster Hunter: World', 2018, '09.08.2018', 'Capcom', 'Capcom',
    'https://store.steampowered.com/app/582010/', '9.0', '89/100', 'aaa', 'Охота, которая объединяет.',
    'Охота, которая объединяет.\n\nКооперативная охота на огромных монстров: изучайте повадки, '
    'готовьте ловушки и собирайте команду из четырёх охотников. Идеальный вход в серию.\n\nMonster '
    'Hunter: World превращает охоту в ритуал. Вы изучаете повадки зверя, готовите снаряжение и '
    'возвращаетесь снова, пока не начнёте понимать его язык. Победа здесь — не финал, а новый '
    'уровень.\n\nЛучший вход в серию и один из лучших кооперативов.',
    'assets/img/games/mhw.jpg', 'assets/img/games/wide/mhw.jpg'
  ),
  (
    15, 'rust', 'Rust', 2018, '08.02.2018', 'Facepunch Studios', 'Facepunch Studios',
    'https://store.steampowered.com/app/252490/', '7.8', '87/100', 'mmo', 'Никому не доверяй.',
    'Никому не доверяй.\n\nЖёсткая MMO-песочница про выживание на голом острове. Первый день вы '
    'собираете палки и камни, второй — уже защищаете базу от соседей с ракетами.\n\nRust начинается '
    'с камня и заканчивается политикой. Вы учитесь доверять только тем, кого проверили, и понимаете, '
    'что самый опасный зверь на острове — человек с дробовиком. Это жестоко, но честно.\n\nСамая '
    'честная и самая беспощадная песочница.',
    'assets/img/games/rust.jpg', 'assets/img/games/wide/rust.jpg'
  ),
  (
    16, 'metro', 'Metro Exodus', 2019, '15.02.2019', '4A Games', 'Deep Silver',
    'https://store.steampowered.com/app/412020/', '8.9', '89/100', 'aaa', 'Дорога на восток.',
    'Дорога на восток.\n\nПостапокалиптический шутер о путешествии Артёма через разрушенную Россию. '
    'Полуоткрытые локации, тишина станций и выбор, который меняет финал.\n\nMetro Exodus — '
    'путешествие не только по России, но и по людям, которые в ней остались. Каждая остановка — '
    'маленький эпизод о том, что человек выбирает, когда мир уже кончился.\n\nОдна из самых цельных '
    'постапокалиптических историй.',
    'assets/img/games/metro.jpg', 'assets/img/games/wide/metro.jpg'
  ),
  (
    17, 'sekiro', 'Sekiro: Shadows Die Twice', 2019, '22.03.2019', 'FromSoftware', 'Activision',
    'https://store.steampowered.com/app/814380/', '9.3', '95/100', 'aaa', 'Одна жизнь, один клинок.',
    'Одна жизнь, один клинок.\n\nЭкшен от FromSoftware про синоби, который возвращает украденное '
    'наследие. Парирование, стойкость и смерть — много смерти.\n\nSekiro — игра про ритм. Пока вы не '
    'научитесь слышать клинки и чувствовать момент парирования, она будет казаться несправедливой. '
    'Потом что-то щёлкает, и бой становится почти музыкой.\n\nСамая дисциплинированная игра '
    'FromSoftware.',
    'assets/img/games/sekiro.jpg', 'assets/img/games/wide/sekiro.jpg'
  ),
  (
    18, 'cyberpunk', 'Cyberpunk 2077', 2020, '10.12.2020', 'CD Projekt Red', 'CD Projekt',
    'https://store.steampowered.com/app/1091500/', '9.2', '95/100', 'aaa', 'Найт-Сити не спит.',
    'Найт-Сити не спит.\n\nОткрытый мир будущего, где корпорации правят, а наёмники выживают. Сюжет, '
    'импланты и город, который запоминается больше, чем любой квест.\n\nCyberpunk 2077 — игра о '
    'городе, который перемалывает людей. Найт-Сити красив, шумен и абсолютно равнодушен к вашим '
    'планам. Через несколько часов вы начинаете понимать, что спасаете не мир, а себя.\n\nПосле '
    'доработки — одна из лучших RPG последних лет.',
    'assets/img/games/cyberpunk.jpg', 'assets/img/games/wide/cyberpunk.jpg'
  ),
  (
    19, 'hades', 'Hades', 2020, '17.09.2020', 'Supergiant Games', 'Supergiant Games',
    'https://store.steampowered.com/app/1145360/', '9.4', '98/100', 'indie', 'Побег из подземного царства.',
    'Побег из подземного царства.\n\nРоглайк про Загрея, который снова и снова пытается сбежать из '
    'Аида. Каждый забег — новые боги, новые сочетания и новые реплики.\n\nHades превращает поражение '
    'в часть сюжета. Каждый раз, когда Загрей умирает, он возвращается домой и слышит новую реплику. '
    'Смерть здесь не наказание, а способ узнать семью лучше.\n\nПочти идеальная игра в своём жанре.',
    'assets/img/games/hades.jpg', 'assets/img/games/wide/hades.jpg'
  ),
  (
    20, 'it-takes-two', 'It Takes Two', 2021, '26.03.2021', 'Hazelight Studios', 'Electronic Arts',
    'https://store.steampowered.com/app/1426210/', '9.2', '96/100', 'aaa',
    'Кооператив, из которого нельзя выйти.',
    'Кооператив, из которого нельзя выйти.\n\nСказка о паре на грани развода, превращённой в кукол. '
    'Все механики построены на двоих: без напарника игру не пройти.\n\nIt Takes Two не оставляет '
    'выбора: играть нужно вдвоём. И это не ограничение, а главная идея. Каждый уровень придумывает '
    'новую механику, чтобы вы с напарником снова почувствовали себя командой.\n\nЛучший кооператив '
    'для двоих за последние годы.',
    'assets/img/games/it-takes-two.jpg', 'assets/img/games/wide/it-takes-two.jpg'
  ),
  (
    21, 'valheim', 'Valheim', 2021, '02.02.2021', 'Iron Gate Studio', 'Coffee Stain Publishing',
    'https://store.steampowered.com/app/892970/', '9.0', '94/100', 'indie', 'Викинги против смерти.',
    'Викинги против смерти.\n\nВыживание в десяти мирах с скандинавской мифологией. Стройте лагерь, '
    'варите мёд, убивайте боссов и не забывайте кормить себя.\n\nValheim начинается с топора и '
    'деревянного дома, а заканчивается путешествием по мирам скандинавской мифологии. Между этими '
    'точками — сотни маленьких побед: первая лодка, первый босс, первая нормальная крыша.\n\nОдин из '
    'самых уютных и одновременно суровых survival-проектов.',
    'assets/img/games/valheim.jpg', 'assets/img/games/wide/valheim.jpg'
  ),
  (
    22, 'new-world', 'New World: Aeternum', 2021, '28.09.2021', 'Amazon Games', 'Amazon Games',
    'https://store.steampowered.com/app/1063730/', '7.7', '79/100', 'mmo', 'Колонизация Аэтернума.',
    'Колонизация Аэтернума.\n\nMMO про остров с ресурсами, фракциями и войнами за территории. Боевка '
    'ближе к экшену, чем к классическим MMO, а крафт — отдельная профессия.\n\nNew World пытается '
    'быть MMO без лишнего шума. Здесь важен не только эндгейм, но и путь: добыча ресурсов, крафт, '
    'войны фракций и ощущение, что остров действительно принадлежит игрокам.\n\nНеровная, но '
    'интересная MMO для своего темпа.',
    'assets/img/games/new-world.jpg', 'assets/img/games/wide/new-world.jpg'
  ),
  (
    23, 'halo', 'Halo Infinite', 2021, '15.11.2021', '343 Industries', 'Xbox Game Studios',
    'https://store.steampowered.com/app/1240440/', '8.3', '87/100', 'aaa', 'Мастер Чиф возвращается.',
    'Мастер Чиф возвращается.\n\nШутер с открытым фрагментом Зета-Халло. Кооперативная кампания и '
    'мультиплеер с классической связкой щитов, гранат и транспорта.\n\nHalo Infinite возвращает '
    'ощущение классического Halo: щиты, гранаты, транспорт и очень точный ритм боя. Кампания даёт '
    'больше свободы, но не теряет фирменной собранности.\n\nДостойное возвращение Мастера Чифа.',
    'assets/img/games/halo.jpg', 'assets/img/games/wide/halo.jpg'
  ),
  (
    24, 'elden-ring', 'Elden Ring', 2022, '25.02.2022', 'FromSoftware', 'Bandai Namco',
    'https://store.steampowered.com/app/1245620/', '9.6', '96/100', 'aaa', 'Между светом и тьмой.',
    'Между светом и тьмой.\n\nОткрытый мир Междуземья от FromSoftware. Исследуйте руины, собирайте '
    'фрагменты Кольца и умирайте красиво — в одиночку или с друзьями.\n\nElden Ring не ведёт за '
    'руку. Она показывает горизонт и говорит: иди. По дороге вы встретите катакомбы, драконов и '
    'людей, которые давно перестали быть людьми. Смысл собирается из того, что вы заметили сами.\n\n'
    'Новая планка для открытых экшенов.',
    'assets/img/games/elden-ring.jpg', 'assets/img/games/wide/elden-ring.jpg'
  ),
  (
    25, 'stray', 'Stray', 2022, '19.07.2022', 'BlueTwelve Studio', 'Annapurna Interactive',
    'https://store.steampowered.com/app/1332010/', '8.7', '96/100', 'indie', 'Киберпанк глазами кота.',
    'Киберпанк глазами кота.\n\nРыжий кот теряется в городе, где живут одни роботы. Атмосферная '
    'головоломка о мелочах, которые делают мир человечнее.\n\nStray работает на простом чуде: вы '
    'кот. Всё остальное — город роботов, головоломки и тихая грусть — вырастает из этого. Игра не '
    'спешит и даёт вам время просто посидеть на краю крыши.\n\nОдна из самых обаятельных игр '
    'последних лет.',
    'assets/img/games/stray.jpg', 'assets/img/games/wide/stray.jpg'
  ),
  (
    26, 'darktide', 'Warhammer 40,000: Darktide', 2022, '30.11.2022', 'Fatshark', 'Fatshark',
    'https://store.steampowered.com/app/1361210/', '8.0', '78/100', 'aaa', 'Кооператив в мрачном будущем.',
    'Кооператив в мрачном будущем.\n\nЧетыре агента Инквизиции зачищают улей Терциум от еретиков. '
    'Ближний бой, стрельба и ощущение, что вас сейчас перемолотит толпа.\n\nDarktide — это командный '
    'хаос в лучшем смысле. Четыре агента, толпа еретиков и очень мало пространства для ошибки. Когда '
    'команда работает слаженно, игра превращается в жестокий танец.\n\nСложный, но очень атмосферный '
    'кооперативный экшен.',
    'assets/img/games/darktide.jpg', 'assets/img/games/wide/darktide.jpg'
  ),
  (
    27, 'bg3', 'Baldur''s Gate 3', 2023, '03.08.2023', 'Larian Studios', 'Larian Studios',
    'https://store.steampowered.com/app/1086940/', '9.8', '97/100', 'aaa', 'D&D без настольного стола.',
    'D&D без настольного стола.\n\nРолевая игра с почти бесконечной свободой: поджигайте, '
    'разговаривайте, соблазняйте и бросайте кубики. Один из лучших кооперативных опытов последних '
    'лет.\n\nBaldur''s Gate 3 даёт свободу, которая сначала пугает. Можно убить важного персонажа, '
    'переспать с ним, превратиться в сыр или пройти половину акта без боя. Игра не ломается — она '
    'отвечает.\n\nОдна из самых богатых RPG в истории.',
    'assets/img/games/bg3.jpg', 'assets/img/games/wide/bg3.jpg'
  ),
  (
    28, 'lethal', 'Lethal Company', 2023, '23.10.2023', 'Zeekerss', 'Zeekerss',
    'https://store.steampowered.com/app/1966720/', '8.5', '97/100', 'indie', 'Работа мечты. Почти.',
    'Работа мечты. Почти.\n\nВы — стажёр корпорации по сбору металлолома на заброшенных лунах. '
    'Голосовой чат, паника и очень странные монстры прилагаются.\n\nLethal Company превращает работу '
    'в кошмар. Вы собираете металлолом на заброшенных лунах, слышите шаги и понимаете, что план '
    'снова не сработает. Смех здесь идёт рука об руку с паникой.\n\nФеномен, который лучше играть с '
    'друзьями.',
    'assets/img/games/lethal.jpg', 'assets/img/games/wide/lethal.jpg'
  ),
  (
    29, 'starfield', 'Starfield', 2023, '06.09.2023', 'Bethesda Game Studios', 'Bethesda Softworks',
    'https://store.steampowered.com/app/1716740/', '8.1', '84/100', 'aaa', 'Космос, который можно потрогать.',
    'Космос, который можно потрогать.\n\nПесочница Bethesda про исследование галактики: корабли, '
    'аванпосты, фракции и сотни планет. Спокойный космос для тех, кто любит копать глубже.\n\n'
    'Starfield — это Bethesda в космосе, со всеми плюсами и странностями. Вы можете стать пиратом, '
    'учёным или просто человеком, который строит аванпост на пустой планете. Смысл — в вашем '
    'расписании.\n\nНе идеальная, но очень просторная песочница.',
    'assets/img/games/starfield.jpg', 'assets/img/games/wide/starfield.jpg'
  ),
  (
    30, 'helldivers2', 'Helldivers 2', 2024, '08.02.2024', 'Arrowhead Game Studios',
    'Sony Interactive Entertainment', 'https://store.steampowered.com/app/553850/', '9.0', '96/100', 'aaa',
    'Управляемая демократия с доставкой.',
    'Управляемая демократия с доставкой.\n\nКооперативный шутер про десантников, которые сражаются '
    'за человечество и оружие массового поражения. Дружественный огонь — часть дизайна.\n\n'
    'Helldivers 2 — игра про командную работу под огнём. Вы и три человека бежите от орды, вызываете '
    'орбитальный удар и понимаете, что он падает слишком близко. Демократия требует жертв.\n\nПочти '
    'идеальная машина для весёлых вечеров.',
    'assets/img/games/helldivers2.jpg', 'assets/img/games/wide/helldivers2.jpg'
  ),
  (
    31, 'palworld', 'Palworld', 2024, '19.01.2024', 'Pocketpair', 'Pocketpair',
    'https://store.steampowered.com/app/1623730/', '8.4', '94/100', 'indie', 'Покемоны с автоматами.',
    'Покемоны с автоматами.\n\nСимулятор выживания, где монстров можно ловить, приручать и '
    'заставлять работать на базе. Или сражаться с ними — как решите.\n\nPalworld начинается как '
    'шутка про покемонов с оружием, а затягивает как нормальное выживание. Вы ловите существ, '
    'строите базы и постепенно превращаетесь в очень сомнительного менеджера.\n\nАбсурдная идея, '
    'реализованная на удивление крепко.',
    'assets/img/games/palworld.jpg', 'assets/img/games/wide/palworld.jpg'
  ),
  (
    32, 'throne', 'Throne and Liberty', 2024, '01.10.2024', 'NCSoft', 'Amazon Games',
    'https://store.steampowered.com/app/2429640/', '7.5', '74/100', 'mmo', 'Осады и большие войны.',
    'Осады и большие войны.\n\nMMO с масштабными осадами замков, свободной трансформацией и сменой '
    'оружия. Мир реагирует на погоду и время суток.\n\nThrone and Liberty пытается совместить '
    'масштабные осады с современной MMO. Здесь много систем, гильдий и политики. Чем больше людей в '
    'вашей команде, тем интереснее становится.\n\nМасштабная MMO для тех, кто любит большие сражения.',
    'assets/img/games/throne.jpg', 'assets/img/games/wide/throne.jpg'
  ),
  (
    33, 'mh-wilds', 'Monster Hunter Wilds', 2025, '28.02.2025', 'Capcom', 'Capcom',
    'https://store.steampowered.com/app/2246340/', '8.6', '89/100', 'aaa', 'Охота без границ.',
    'Охота без границ.\n\nНовая глава Monster Hunter: бесшовные локации, стаи монстров и погодные '
    'катаклизмы. Кооператив на четверых остаётся главным аттракционом.\n\nMonster Hunter Wilds '
    'делает охоту более бесшовной: меньше загрузок, больше жизни вокруг. Стаи, погода и миграции '
    'превращают карту в подвижную экосистему, к которой нужно приспосабливаться.\n\nСмелая эволюция '
    'серии, хоть и не без шероховатостей.',
    'assets/img/games/mh-wilds.jpg', 'assets/img/games/wide/mh-wilds.jpg'
  ),
  (
    34, 'split-fiction', 'Split Fiction', 2025, '06.03.2025', 'Hazelight Studios', 'Electronic Arts',
    'https://store.steampowered.com/app/2001120/', '9.1', '97/100', 'aaa', 'Ещё одно приключение на двоих.',
    'Ещё одно приключение на двоих.\n\nКооперативный экшен от авторов It Takes Two: две писательницы '
    'застревают в собственных мирах. Каждый уровень меняет правила, и это лучшее в игре.\n\nSplit '
    'Fiction отправляет двух писательниц в миры, которые они сами придумали. Каждый уровень меняет '
    'правила, а кооператив остаётся единственным способом пройти дальше. Фантазия здесь — главная '
    'механика.\n\nЕщё один уверенный кооператив от Hazelight.',
    'assets/img/games/split-fiction.jpg', 'assets/img/games/wide/split-fiction.jpg'
  ),
  (
    35, 'clair-obscur', 'Clair Obscur: Expedition 33', 2025, '24.04.2025', 'Sandfall Interactive',
    'Kepler Interactive', 'https://store.steampowered.com/app/1903340/', '9.5', '95/100', 'aaa',
    'Живопись, которая убивает.',
    'Живопись, которая убивает.\n\nПошаговая RPG о художниках, которые стирают людей с полотна '
    'реальности. Элегантный бой, сильная музыка и один из самых неожиданных сюжетов года.\n\nClair '
    'Obscur: Expedition 33 выглядит как ожившая картина и говорит о смерти с уважением. Пошаговые '
    'бои здесь быстрые, а история — о людях, которые знают дату своего исчезновения и всё равно идут '
    'вперёд.\n\nОдна из главных RPG 2025 года.',
    'assets/img/games/clair-obscur.jpg', 'assets/img/games/wide/clair-obscur.jpg'
  ),
  (
    36, 'dune', 'Dune: Awakening', 2025, '10.06.2025', 'Funcom', 'Funcom',
    'https://store.steampowered.com/app/1172710/', '8.2', '84/100', 'mmo', 'Арракис не прощает.',
    'Арракис не прощает.\n\nMMO-выживание на пустынной планете: специи, песчаные черви и борьба за '
    'воду. Кооператив и политика идут рука об руку.\n\nDune: Awakening строит выживание вокруг '
    'пустыни. Вода, специи и песчаные черви формируют экономику и маршруты. Это MMO, в которой '
    'пейзаж — такой же противник, как другие игроки.\n\nАмбициозный, но атмосферный эксперимент.',
    'assets/img/games/dune.jpg', 'assets/img/games/wide/dune.jpg'
  ),
  (
    37, 'doom-dark-ages', 'DOOM: The Dark Ages', 2025, '15.05.2025', 'id Software', 'Bethesda Softworks',
    'https://store.steampowered.com/app/3017860/', '8.7', '89/100', 'aaa', 'Средневековый ад.',
    'Средневековый ад.\n\nПриквел DOOM: Палач сражается с демонами в мире, где щит и цепь важнее '
    'укрытий. Медленнее, тяжелее и всё так же яростно.\n\nDOOM: The Dark Ages замедляет Палача, но '
    'не делает его мягче. Щит, цепь и тяжёлое оружие превращают бой в средневековый ритуал. Здесь '
    'меньше прыжков и больше веса.\n\nСмелый поворот серии в сторону тяжести.',
    'assets/img/games/doom-dark-ages.jpg', 'assets/img/games/wide/doom-dark-ages.jpg'
  ),
  (
    38, 'subnautica2', 'Subnautica 2', 2026, '2026', 'Unknown Worlds', 'Krafton',
    'https://store.steampowered.com/app/1962700/', NULL, 'ожидается', 'next', 'Океан снова зовёт.',
    'Океан снова зовёт.\n\nНовое выживание в подводном мире, теперь с кооперативом. Стройте базу, '
    'исследуйте глубины и не светите фонарём там, где не стоит.\n\nSubnautica 2 возвращает нас под '
    'воду, но теперь с кооперативом. Океан снова красив и опасен, а чувство глубины работает лучше '
    'любой карты. Главное — не светить фонарём туда, где он не нужен.\n\nОдин из самых ожидаемых '
    'кооперативных релизов.',
    'assets/img/games/subnautica2.jpg', 'assets/img/games/wide/subnautica2.jpg'
  ),
  (
    39, 're-requiem', 'Resident Evil Requiem', 2026, '27.02.2026', 'Capcom', 'Capcom',
    'https://store.steampowered.com/app/3764200/', NULL, 'ожидается', 'next',
    'Ужас возвращается в Раккун-Сити.',
    'Ужас возвращается в Раккун-Сити.\n\nПродолжение резидентской линии: расследование в городе, где '
    'прошлое так и не отпустило. Свет, звук и пустые коридоры работают лучше любого монстра.\n\n'
    'Resident Evil Requiem возвращает ужас в знакомые коридоры, но обещает новую историю. Свет, звук '
    'и пустота снова становятся главными инструментами. Пока рано судить, но ингредиенты '
    'правильные.\n\nОжидание с осторожным оптимизмом.',
    'assets/img/games/re-requiem.jpg', 'assets/img/games/wide/re-requiem.jpg'
  ),
  (
    40, 'nioh3', 'Nioh 3', 2026, '06.02.2026', 'Team Ninja', 'Koei Tecmo',
    'https://store.steampowered.com/app/3681010/', NULL, 'ожидается', 'next', 'Самурайский экшен возвращается.',
    'Самурайский экшен возвращается.\n\nТретья часть про ёкаев и мастерство клинка. Смена стоек, '
    'духи-хранители и кооператив для тех, кому мало одного удара.\n\nNioh 3 обещает больше ёкаев, '
    'больше оружия и ещё более быстрый бой. Серия всегда держалась на ощущении контроля, и новая '
    'часть, судя по всему, не собирается упрощаться.\n\nПотенциально лучшая часть серии — проверим '
    'на релизе.',
    'assets/img/games/nioh3.jpg', 'assets/img/games/wide/nioh3.jpg'
  ),
  (
    41, 'hades2', 'Hades II', 2024, '06.05.2024', 'Supergiant Games', 'Supergiant Games',
    'https://store.steampowered.com/app/1145350/', '9.2', '94/100', 'indie', 'Ночь, которая не кончается.',
    'Ночь, которая не кончается.\n\nМелиноя, сестра Загрея, идёт против самого времени. Подземный '
    'мир стал больше, злее и красивее: новые боги, новые проклятия и всё та же привычка Supergiant '
    'превращать смерть в разговор о семье.\n\nHades II не пытается переизобрести формулу первой '
    'части — она её углубляет. Каждый забег ощущается как глава сериала: вы меняете оружие, слушаете '
    'новую реплику и внезапно понимаете, что уже полночи спорите с Гекатой о том, кто здесь на самом '
    'деле чудовище.',
    'assets/img/games/hades2.jpg', 'assets/img/games/wide/hades2.jpg'
  ),
  (
    42, 'silksong', 'Hollow Knight: Silksong', 2025, '04.09.2025', 'Team Cherry', 'Team Cherry',
    'https://store.steampowered.com/app/1030300/', '9.1', '92/100', 'indie', 'Королевство шёлка и шипов.',
    'Королевство шёлка и шипов.\n\nХорнет возвращается в новое королевство — Фарлум. Вместо '
    'медленного исследования Халлоунеста здесь больше скорости, акробатики и смертоносных насекомых, '
    'которые не ждут, пока вы закончите любоваться пейзажем.\n\nSilksong — не DLC и не копия Hollow '
    'Knight. Хорнет двигается иначе, дерётся иначе и рассказывает историю через резкие, почти '
    'музыкальные переходы между комнатами. Мир стал плотнее, а секреты — злее.',
    'assets/img/games/silksong.jpg', 'assets/img/games/wide/silksong.jpg'
  ),
  (
    43, 'nightreign', 'Elden Ring Nightreign', 2025, '30.05.2025', 'FromSoftware', 'Bandai Namco',
    'https://store.steampowered.com/app/2622380/', '8.3', '85/100', 'aaa',
    'Три ночи, один круг, никаких вторых шансов.',
    'Три ночи, один круг, никаких вторых шансов.\n\nЭксперимент FromSoftware: три игрока, сжатые '
    'забеги по знакомым землям и боссы, которых нельзя победить в одиночку. Nightreign берёт язык '
    'Elden Ring и переписывает его в формат стремительного кооперативного выживания.\n\nЗдесь нет '
    'времени на долгие прогулки. За три игровых дня вы успеваете собрать билд, найти союзников и '
    'понять, что ваш напарник снова взял не то оружие. Именно в этой спешке и рождается новый опыт.',
    'assets/img/games/nightreign.jpg', 'assets/img/games/wide/nightreign.jpg'
  ),
  (
    44, 'kcd2', 'Kingdom Come: Deliverance II', 2025, '04.02.2025', 'Warhorse Studios', 'Deep Silver',
    'https://store.steampowered.com/app/1771300/', '9.0', '92/100', 'aaa', 'История без драконов.',
    'История без драконов.\n\nИндирж вновь оказывается в центре войны, интриг и очень бытовых '
    'проблем. Kingdom Come: Deliverance II — редкая RPG, где меч надо точить, одежду чистить, а '
    'разговор с крестьянином может стоить больше, чем битва.\n\nWarhorse сделали мир, в котором '
    'грязь, голод и репутация важнее эпического пророчества. Вы не избранный — вы выживший. И именно '
    'поэтому каждая победа здесь ощущается личной.',
    'assets/img/games/kcd2.jpg', 'assets/img/games/wide/kcd2.jpg'
  ),
  (
    45, 'arcraiders', 'ARC Raiders', 2025, '30.10.2025', 'Embark Studios', 'Embark Studios',
    'https://store.steampowered.com/app/1808500/', '8.6', '87/100', 'aaa', 'Наверху — машины. Внизу — люди.',
    'Наверху — машины. Внизу — люди.\n\nМир после вторжения машин: вы спускаетесь на поверхность за '
    'добычей, стараетесь не шуметь и решаете, кому можно доверять. ARC Raiders смешивает '
    'экстракшен-шутер с редким для жанра гуманизмом.\n\nЗдесь можно играть агрессивно, но игра не '
    'требует этого. Иногда лучший ход — помочь незнакомцу, отдать аптечку и уйти с пустыми руками. '
    'Embark построили мир, где выживание не обязано быть подлостью.',
    'assets/img/games/arcraiders.jpg', 'assets/img/games/wide/arcraiders.jpg'
  ),
  (
    46, 'peak', 'PEAK', 2025, '16.06.2025', 'Aggro Crab, Landfall', 'Aggro Crab, Landfall',
    'https://store.steampowered.com/app/3527290/', '8.5', '94/100', 'indie',
    'Гора не прощает ошибок. Друзья — тем более.',
    'Гора не прощает ошибок. Друзья — тем более.\n\nЧетыре альпиниста, один маршрут и очень много '
    'способов испортить друг другу подъём. PEAK — кооперативное восхождение, где голод, холод и '
    'чувство юмора важнее любого снаряжения.\n\nЭто не симулятор альпинизма, а симулятор совместной '
    'паники. Вы тащите друга на верёвке, делите последний батончик и пытаетесь не смотреть вниз. '
    'Смешно ровно до того момента, пока кто-то не сорвётся.',
    'assets/img/games/peak.jpg', 'assets/img/games/wide/peak.jpg'
  ),
  (
    47, 'repo', 'R.E.P.O.', 2025, '26.02.2025', 'semiwork', 'semiwork',
    'https://store.steampowered.com/app/3241660/', '8.2', '95/100', 'indie',
    'Не разбейте то, что не должны были брать.',
    'Не разбейте то, что не должны были брать.\n\nРабота простая: зайти в заброшенное место, найти '
    'ценные вещи и донести их до грузовика. Проблема в том, что вещи хрупкие, монстры голодные, а '
    'ваши друзья не умеют держать предметы.\n\nR.E.P.O. доводит физику до абсурда: вы тащите хрупкую '
    'вазу через тёмный коридор, а напарник решает, что самый короткий путь — через окно. Смех здесь '
    'рождается из провала, а не из шуток.',
    'assets/img/games/repo.jpg', 'assets/img/games/wide/repo.jpg'
  ),
  (
    48, 'dispatch', 'Dispatch', 2025, '22.10.2025', 'AdHoc Studio', 'AdHoc Studio',
    'https://store.steampowered.com/app/2592160/', '8.8', '92/100', 'indie',
    'Супергерои тоже звонят в поддержку.',
    'Супергерои тоже звонят в поддержку.\n\nДиспетчерская супергеройского агентства — место, где '
    'костюмы пахнут потом, а спасение мира зависит от того, успеете ли вы переключить канал. '
    'Dispatch — интерактивная комедия о людях, которые остались за кулисами.\n\nВы отвечаете на '
    'звонки, распределяете героев и пытаетесь не сойти с ума от их эго. Между сменами — разговоры, '
    'флирт и маленькие решения, которые меняют не сюжет мира, а жизни конкретных людей.',
    'assets/img/games/dispatch.jpg', 'assets/img/games/wide/dispatch.jpg'
  ),
  (
    49, 'contentwarning', 'Content Warning', 2024, '01.04.2024', 'Landfall', 'Landfall',
    'https://store.steampowered.com/app/2881650/', '8.0', '93/100', 'indie',
    'Снимите хоррор, пока он не снял вас.',
    'Снимите хоррор, пока он не снял вас.\n\nВы и друзья спускаетесь в подземелья с камерой, чтобы '
    'снять вирусный ролик. Чем страшнее материал, тем больше просмотров — и тем выше шанс не '
    'вернуться.\n\nContent Warning смеётся над культурой контента, но не превращается в пародию. '
    'Сначала вы шутите, потом камера начинает дрожать, а потом понимаете, что бежите без света и без '
    'плана.',
    'assets/img/games/contentwarning.jpg', 'assets/img/games/wide/contentwarning.jpg'
  ),
  (
    50, 'vrising', 'V Rising', 2022, '17.05.2022', 'Stunlock Studios', 'Stunlock Studios',
    'https://store.steampowered.com/app/1604030/', '8.4', '88/100', 'indie',
    'Постройте замок. Переживите рассвет.',
    'Постройте замок. Переживите рассвет.\n\nВы просыпаетесь слабым вампиром и постепенно '
    'становитесь грозой региона. Днём прячьтесь от солнца, ночью собирайте ресурсы, стройте замок и '
    'воюйте за территории.\n\nV Rising умеет быть и уютным строителем, и жёсткой PvP-песочницей. Всё '
    'зависит от сервера и от того, насколько вы готовы доверять соседям. В любом случае солнце здесь '
    '— полноценный враг.',
    'assets/img/games/vrising.jpg', 'assets/img/games/wide/vrising.jpg'
  ),
  (
    51, 'grayzone', 'Gray Zone Warfare', 2024, '30.04.2024', 'Madfinger Games', 'Madfinger Games',
    'https://store.steampowered.com/app/2479810/', '7.8', '78/100', 'aaa', 'Один выстрел решает всё.',
    'Один выстрел решает всё.\n\nТактический шутер в открытом мире, где важнее не реакция, а '
    'подготовка. Изучайте маршруты, следите за ветром и не забывайте, что за вами могут наблюдать не '
    'только враги.\n\nGray Zone Warfare продаёт не героизм, а напряжение. Вы ползёте по кустам '
    'двадцать минут, чтобы сделать один точный выстрел, — и это может быть лучшим моментом вечера.',
    'assets/img/games/grayzone.jpg', 'assets/img/games/wide/grayzone.jpg'
  ),
  (
    52, 'marvelrivals', 'Marvel Rivals', 2024, '06.12.2024', 'NetEase Games', 'NetEase Games',
    'https://store.steampowered.com/app/2767030/', '8.2', '83/100', 'aaa',
    'Команда супергероев без супергеройских проблем.',
    'Команда супергероев без супергеройских проблем.\n\nКрасочный командный шутер, где Ракета и Грут '
    'могут оказаться в одном отряде с Доктором Стрэнджем. Быстрые матчи, разрушаемые локации и очень '
    'много хаоса.\n\nMarvel Rivals не стесняется быть игрой. Здесь нет мрачной драмы — есть '
    'командные ульты, странные составы и момент, когда вся команда одновременно решает, что пора '
    'идти в атаку. Иногда это даже работает.',
    'assets/img/games/marvelrivals.jpg', 'assets/img/games/wide/marvelrivals.jpg'
  ),
  (
    53, 'firstdescendant', 'The First Descendant', 2024, '02.07.2024', 'Nexon Games', 'Nexon',
    'https://store.steampowered.com/app/2074920/', '7.4', '72/100', 'aaa', 'Наследники против колоссов.',
    'Наследники против колоссов.\n\nКооперативный лутер-шутер про потомков, которые защищают '
    'человечество от гигантских существ. Много оружия, умений и очень быстрый ритм.\n\nThe First '
    'Descendant не пытается быть глубокой драмой. Это игра про то, как собрать команду, включить '
    'музыку и снести боссу половину здоровья красивым комбо. Иногда этого достаточно.',
    'assets/img/games/firstdescendant.jpg', 'assets/img/games/wide/firstdescendant.jpg'
  ),
  (
    54, 'spacemarine2', 'Warhammer 40,000: Space Marine 2', 2024, '09.09.2024', 'Saber Interactive',
    'Focus Entertainment', 'https://store.steampowered.com/app/2183900/', '8.7', '89/100', 'aaa',
    'Только война. И очень много врагов.',
    'Только война. И очень много врагов.\n\nТит возвращается, чтобы сражаться с тиранидами в мрачном '
    'будущем Warhammer 40,000. Тяжёлый бой, цепные мечи и ощущение, что вы действительно '
    'космодесантник.\n\nSpace Marine 2 понимает, что делает: даёт вам болтер, цепной меч и стену '
    'врагов. Сюжет здесь — повод для эпических сцен, и он честно выполняет свою работу.',
    'assets/img/games/spacemarine2.jpg', 'assets/img/games/wide/spacemarine2.jpg'
  ),
  (
    55, 'pacificdrive', 'Pacific Drive', 2024, '22.02.2024', 'Ironwood Studios', 'Kepler Interactive',
    'https://store.steampowered.com/app/1458140/', '8.4', '88/100', 'indie',
    'Дорога, которая не хочет, чтобы вы вернулись.',
    'Дорога, которая не хочет, чтобы вы вернулись.\n\nВы едете по аномальной зоне на старом '
    'универсале, чините его подручными средствами и пытаетесь понять, что случилось с миром. Pacific '
    'Drive — дорожное выживание с очень человеческим лицом.\n\nЗдесь нет зомби и боссов. Есть '
    'машина, радио и аномалии, которые меняют правила каждый выезд. Чем дольше вы в зоне, тем '
    'сильнее привязываетесь к этой железной коробке.',
    'assets/img/games/pacificdrive.jpg', 'assets/img/games/wide/pacificdrive.jpg'
  ),
  (
    56, 'sonsoftheforest', 'Sons of the Forest', 2023, '23.02.2023', 'Endnight Games', 'Newnight',
    'https://store.steampowered.com/app/1326470/', '8.5', '89/100', 'aaa', 'Остров, который строит вас заново.',
    'Остров, который строит вас заново.\n\nВы ищете пропавшего миллиардера на острове, где всё хочет '
    'вас съесть. Стройте укрытие, рубите деревья, спускайтесь в пещеры — и не забывайте, что '
    'каннибалы тоже умеют учиться.\n\nSons of the Forest — прямой наследник The Forest, но с большим '
    'миром и более свободным строительством. Здесь страшно не из-за скримеров, а из-за тишины между '
    'шагами.',
    'assets/img/games/sonsoftheforest.jpg', 'assets/img/games/wide/sonsoftheforest.jpg'
  ),
  (
    57, 'outlasttrials', 'The Outlast Trials', 2024, '05.03.2024', 'Red Barrels', 'Red Barrels',
    'https://store.steampowered.com/app/1304930/', '8.1', '86/100', 'aaa',
    'Испытание, из которого не выходят прежними.',
    'Испытание, из которого не выходят прежними.\n\nRed Barrels переносят фирменный ужас в формат '
    'кооперативных испытаний. Вы и ещё три человека проходите комнаты, полные ловушек, '
    'преследователей и очень плохих решений.\n\nThe Outlast Trials не теряет жестокости серии, но '
    'добавляет командную панику. Когда один игрок бежит, остальные тоже бегут. Иногда прямо в '
    'ловушку.',
    'assets/img/games/outlasttrials.jpg', 'assets/img/games/wide/outlasttrials.jpg'
  ),
  (
    58, 'readyornot', 'Ready or Not', 2023, '13.12.2023', 'VOID Interactive', 'VOID Interactive',
    'https://store.steampowered.com/app/1144200/', '8.6', '90/100', 'aaa', 'Входите тихо. Выходите живыми.',
    'Входите тихо. Выходите живыми.\n\nТактический шутер про SWAT: заложники, ордера, двери и очень '
    'мало права на ошибку. Здесь ценят не скорость, а дисциплину — и умение слушать напарника.\n\n'
    'Ready or Not не прощает героизма. Один неверный выстрел может стоить жизни заложнику, а один '
    'пропущенный угол — всей команде. Это игра про процедуры, которые спасают людей.',
    'assets/img/games/readyornot.jpg', 'assets/img/games/wide/readyornot.jpg'
  ),
  (
    59, 'alanwake2', 'Alan Wake 2', 2023, '27.10.2023', 'Remedy Entertainment', 'Epic Games Publishing',
    'https://store.steampowered.com/app/1087100/', '8.9', '89/100', 'aaa', 'История пишет автора.',
    'История пишет автора.\n\nПродолжение Alan Wake — это одновременно детектив, хоррор и метаигра о '
    'творчестве. Два героя, два взгляда на одну тайну и очень много тьмы.\n\nRemedy играют с формой: '
    'вы расследуете исчезновения, меняете сцены и читаете письма, которые знают о вас больше, чем '
    'вы. Сюжет не боится быть странным — и именно поэтому работает.',
    'assets/img/games/alanwake2.jpg', 'assets/img/games/wide/alanwake2.jpg'
  ),
  (
    60, 'lostark', 'Lost Ark', 2019, '04.12.2019', 'Smilegate RPG', 'Amazon Games',
    'https://store.steampowered.com/app/1599340/', '8.0', '82/100', 'mmo', 'Мир, где конец света уже случился.',
    'Мир, где конец света уже случился.\n\nИзометрическая MMO с быстрым экшеном и огромным '
    'количеством контента. Рейды, острова, коллекции и очень длинная дорога к эндгейму.\n\nLost Ark '
    'берёт лучшие идеи Diablo и MMO, но не пытается быть чем-то большим. Это игра про ритм: '
    'заходите, чистите подземелья, собираете лут и возвращаетесь завтра.',
    'assets/img/games/lostark.jpg', 'assets/img/games/wide/lostark.jpg'
  ),
  (
    61, 'signalis', 'Signalis', 2022, '27.10.2022', 'rose-engine', 'Humble Games',
    'https://store.steampowered.com/app/1262350/', '8.8', '96/100', 'indie', 'Космос, память и чужие лица.',
    'Космос, память и чужие лица.\n\nРетро-хоррор про андроида, который ищет потерянную напарницу на '
    'заброшенной станции. Мало патронов, много тишины и очень много вопросов без ответов.\n\n'
    'Signalis выглядит как игра с PlayStation 1, но говорит о вещах, которые не устарели: о долге, '
    'любви и том, что остаётся от человека после смерти. Каждая комната здесь — часть головоломки.',
    'assets/img/games/signalis.jpg', 'assets/img/games/wide/signalis.jpg'
  ),
  (
    62, 'gtfo', 'GTFO', 2021, '10.12.2021', '10 Chambers', '10 Chambers',
    'https://store.steampowered.com/app/493520/', '8.0', '86/100', 'indie',
    'Спускайтесь тихо. Поднимайтесь быстро.',
    'Спускайтесь тихо. Поднимайтесь быстро.\n\nХардкорный кооперативный шутер про команду '
    'заключённых, которые спускаются в подземный комплекс за образцами. Здесь нельзя бежать вперёд и '
    'стрелять во всё, что движется.\n\nGTFO требует дисциплины: сканировать, планировать, экономить '
    'патроны и турели. Ошибка одного игрока слышна всей команде. Именно поэтому победа ощущается '
    'общей.',
    'assets/img/games/gtfo.jpg', 'assets/img/games/wide/gtfo.jpg'
  ),
  (
    63, 'back4blood', 'Back 4 Blood', 2021, '12.10.2021', 'Turtle Rock Studios', 'Warner Bros. Games',
    'https://store.steampowered.com/app/924970/', '7.0', '70/100', 'aaa', 'Карточная колода против орды.',
    'Карточная колода против орды.\n\nДуховный наследник Left 4 Dead с карточной системой билдов. '
    'Собирайте команду, выбирайте карты и пробивайтесь через заражённые районы.\n\nBack 4 Blood '
    'вышла неровной, но кооперативный цикл всё ещё работает. Карты добавляют реиграбельность и '
    'заставляют думать о составе команды, а не только о патронах.',
    'assets/img/games/back4blood.jpg', 'assets/img/games/wide/back4blood.jpg'
  ),
  (
    64, 'inscryption', 'Inscryption', 2021, '19.10.2021', 'Daniel Mullins Games', 'Devolver Digital',
    'https://store.steampowered.com/app/1092790/', '8.9', '97/100', 'indie',
    'Игра, которая знает, что вы играете.',
    'Игра, которая знает, что вы играете.\n\nНа первый взгляд это карточный roguelike в хижине '
    'лесника. На деле — многослойная история о играх, авторстве и том, кто на самом деле держит '
    'колоду.\n\nInscryption постоянно меняет правила и не предупреждает. Чем дальше вы заходите, тем '
    'меньше доверяете интерфейсу. Это редкая игра, которую нельзя объяснить, не испортив впечатление.',
    'assets/img/games/inscryption.jpg', 'assets/img/games/wide/inscryption.jpg'
  ),
  (
    65, 'deeprock', 'Deep Rock Galactic', 2020, '13.05.2020', 'Ghost Ship Games', 'Coffee Stain Publishing',
    'https://store.steampowered.com/app/548430/', '8.9', '97/100', 'indie', 'Rock and Stone!',
    'Rock and Stone!\n\nЧетыре космических гнома спускаются в procedurally generated пещеры за рудой '
    'и уничтожают всё, что шевелится. Кооператив, где каждый класс действительно нужен.\n\nDeep Rock '
    'Galactic — редкий кооперативный шутер без токсичности. Здесь принято спасать напарника, '
    'делиться пивом и кричать «Rock and Stone» в случайный момент. Это часть дизайна.',
    'assets/img/games/deeprock.jpg', 'assets/img/games/wide/deeprock.jpg'
  ),
  (
    66, 'phasmophobia', 'Phasmophobia', 2020, '18.09.2020', 'Kinetic Games', 'Kinetic Games',
    'https://store.steampowered.com/app/739630/', '8.3', '94/100', 'indie', 'Не называйте его по имени.',
    'Не называйте его по имени.\n\nКоманда охотников за призраками исследует дома с камерами, '
    'датчиками и голосовым чатом. Чем больше вы говорите, тем больше шансов, что вам ответят.\n\n'
    'Phasmophobia страшна не монстрами, а ожиданием. Вы стоите в тёмной комнате, смотрите на '
    'термометр и слышите, как напарник шепчет: «Оно рядом». Потом свет гаснет.',
    'assets/img/games/phasmophobia.jpg', 'assets/img/games/wide/phasmophobia.jpg'
  ),
  (
    67, 'seaofthieves', 'Sea of Thieves', 2020, '03.06.2020', 'Rare', 'Xbox Game Studios',
    'https://store.steampowered.com/app/1172620/', '8.0', '88/100', 'mmo', 'Ваша команда. Ваша история.',
    'Ваша команда. Ваша история.\n\nПиратская песочница, где нет уровней и обязательного сюжета. '
    'Есть корабль, карта и другие игроки, которые могут стать друзьями или проблемой.\n\nSea of '
    'Thieves живёт за счёт историй, которые вы создаёте сами. Погоня, шторм, предательство и '
    'случайный остров с сокровищами — вот настоящий контент.',
    'assets/img/games/seaofthieves.jpg', 'assets/img/games/wide/seaofthieves.jpg'
  ),
  (
    68, 'hunt', 'Hunt: Showdown', 2019, '27.08.2019', 'Crytek', 'Crytek',
    'https://store.steampowered.com/app/594650/', '8.2', '84/100', 'aaa', 'Охота, в которой вы — тоже добыча.',
    'Охота, в которой вы — тоже добыча.\n\nБолота Луизианы, монстры и охотники, которые пришли за '
    'наградой. Hunt: Showdown — медленный PvPvE-шутер, где звук важнее прицела.\n\nВы выслеживаете '
    'чудовище, но слышите чужие шаги. Теперь вы знаете, что не одни. В Hunt именно это знание '
    'превращает игру в триллер.',
    'assets/img/games/hunt.jpg', 'assets/img/games/wide/hunt.jpg'
  ),
  (
    69, 'discoelysium', 'Disco Elysium', 2019, '15.10.2019', 'ZA/UM', 'ZA/UM',
    'https://store.steampowered.com/app/632470/', '9.2', '93/100', 'indie',
    'Детектив, который расследует сам себя.',
    'Детектив, который расследует сам себя.\n\nБезымянный детектив просыпается с амнезией и берётся '
    'за дело об убийстве. Почти вся игра — это разговоры, мысли и голоса в голове, которые спорят '
    'друг с другом.\n\nDisco Elysium — не игра про победу. Это игра про попытку остаться человеком. '
    'Ваши навыки — не цифры, а характеры, и они буквально разговаривают с вами.',
    'assets/img/games/discoelysium.jpg', 'assets/img/games/wide/discoelysium.jpg'
  ),
  (
    70, 'control', 'Control', 2019, '27.08.2019', 'Remedy Entertainment', '505 Games',
    'https://store.steampowered.com/app/870780/', '8.6', '88/100', 'aaa', 'Дом, который не подчиняется физике.',
    'Дом, который не подчиняется физике.\n\nДжесси Фейден приходит в Федеральное бюро контроля, '
    'чтобы найти брата, и обнаруживает здание, которое живёт по своим законам. Телекинез, странные '
    'предметы и бюрократия как хоррор.\n\nControl — игра про архитектуру и власть. Вы носитесь по '
    'бруталистским коридорам, швыряете бетонные блоки и читаете документы, которые постепенно '
    'собираются в очень странную картину.',
    'assets/img/games/control.jpg', 'assets/img/games/wide/control.jpg'
  ),
  (
    71, 'a-way-out', 'A Way Out', 2018, '23.03.2018', 'Hazelight Studios', 'Electronic Arts',
    'https://store.steampowered.com/app/1222700/', '8.3', '88/100', 'aaa',
    'Побег, который возможен только вдвоём.',
    'Побег, который возможен только вдвоём.\n\nДва заключённых, один побег и обязательный '
    'кооператив. A Way Out рассказывает историю через совместные действия: один отвлекает, другой '
    'открывает дверь.\n\nHazelight строят игру вокруг доверия. Здесь нельзя пройти уровень в '
    'одиночку — и в этом весь смысл. Иногда достаточно просто ждать напарника.',
    'assets/img/games/a-way-out.jpg', 'assets/img/games/wide/a-way-out.jpg'
  ),
  (
    72, 'frostpunk', 'Frostpunk', 2018, '24.04.2018', '11 bit studios', '11 bit studios',
    'https://store.steampowered.com/app/323190/', '8.8', '89/100', 'indie', 'Город на краю мира.',
    'Город на краю мира.\n\nПоследний город человечества выживает среди вечной зимы. Вы строите '
    'генератор, распределяете людей и принимаете решения, которые не становятся проще от того, что '
    'они необходимы.\n\nFrostpunk — игра про цену порядка. Каждый закон, который вы принимаете, '
    'помогает выжить и одновременно делает город чуть менее человечным. Баланс между этими вещами и '
    'есть игра.',
    'assets/img/games/frostpunk.jpg', 'assets/img/games/wide/frostpunk.jpg'
  ),
  (
    73, 'nomanssky', 'No Man''s Sky', 2016, '12.08.2016', 'Hello Games', 'Hello Games',
    'https://store.steampowered.com/app/275850/', '8.0', '80/100', 'indie', 'Бесконечное небо.',
    'Бесконечное небо.\n\nКосмическая песочница, где можно сесть в корабль и улететь к другой '
    'звезде. Стройте базы, исследуйте планеты, торгуйте и слушайте тишину между прыжками.\n\nNo '
    'Man''s Sky прошла путь от скандального релиза до одной из самых щедрых игр. Здесь нет финальной '
    'цели — есть маршрут, который вы выбираете сами.',
    'assets/img/games/nomanssky.jpg', 'assets/img/games/wide/nomanssky.jpg'
  ),
  (
    74, 'ffxiv', 'Final Fantasy XIV Online', 2013, '27.08.2013', 'Square Enix', 'Square Enix',
    'https://store.steampowered.com/app/39210/', '8.8', '90/100', 'mmo', 'История, которую проживают миллионы.',
    'История, которую проживают миллионы.\n\nMMO с одной из лучших сюжетных кампаний в жанре. Вы '
    'начинаете как авантюрист, а заканчиваете как часть большой истории о надежде, памяти и цене '
    'мира.\n\nFinal Fantasy XIV умеет быть и социальной песочницей, и большим романом. Здесь можно '
    'годами играть ради рейдов, а можно — ради того, чтобы узнать, что случится с персонажами дальше.',
    'assets/img/games/ffxiv.jpg', 'assets/img/games/wide/ffxiv.jpg'
  ),
  (
    75, 'guildwars2', 'Guild Wars 2', 2012, '28.08.2012', 'ArenaNet', 'NCSoft',
    'https://store.steampowered.com/app/1284210/', '8.5', '88/100', 'mmo', 'Мир, который не требует подписки.',
    'Мир, который не требует подписки.\n\nMMO без ежемесячной платы, с акцентом на открытое '
    'исследование и совместные события. Здесь не нужно гриндить уровни, чтобы увидеть интересное.\n\n'
    'Guild Wars 2 построена вокруг идеи, что мир должен быть доступен. Вы можете вернуться через год '
    'и всё равно найти занятие. Это редкая щедрость для жанра.',
    'assets/img/games/guildwars2.jpg', 'assets/img/games/wide/guildwars2.jpg'
  );

INSERT INTO game_categories (game_id, category_id) VALUES
  (1, 1), (1, 2), (2, 2), (2, 3), (3, 4), (3, 3), (4, 2), (4, 1), (5, 4), (6, 1), (7, 3), (7, 2), (7, 5),
  (8, 1), (8, 3), (9, 5), (10, 4), (11, 1), (12, 4), (12, 2), (12, 3), (13, 1), (13, 5), (14, 3), (14, 1),
  (15, 4), (15, 2), (15, 3), (16, 1), (16, 5), (17, 1), (18, 1), (18, 5), (19, 1), (20, 3), (20, 1), (21, 2),
  (21, 3), (22, 4), (22, 3), (23, 5), (23, 3), (24, 1), (25, 1), (26, 3), (26, 5), (27, 1), (27, 3), (28, 3),
  (28, 2), (29, 1), (29, 5), (30, 3), (30, 5), (31, 3), (31, 2), (32, 4), (33, 3), (33, 1), (34, 3), (34, 1),
  (35, 1), (36, 4), (36, 2), (36, 3), (37, 5), (37, 1), (38, 2), (38, 3), (39, 1), (39, 2), (39, 5), (40, 1),
  (40, 3), (41, 1), (42, 1), (43, 3), (43, 1), (44, 1), (45, 5), (45, 3), (46, 3), (46, 2), (47, 3), (48, 1),
  (49, 3), (50, 2), (50, 3), (51, 5), (51, 2), (52, 5), (52, 3), (53, 5), (53, 3), (54, 5), (54, 3), (55, 2),
  (55, 1), (56, 2), (56, 3), (57, 3), (57, 2), (58, 5), (58, 3), (59, 1), (59, 5), (60, 4), (61, 1), (62, 3),
  (62, 5), (63, 3), (63, 5), (64, 1), (65, 3), (65, 5), (66, 3), (66, 2), (67, 4), (67, 3), (68, 5), (68, 3),
  (69, 1), (70, 1), (70, 5), (71, 3), (71, 1), (72, 2), (72, 1), (73, 2), (73, 4), (74, 4), (74, 1), (75, 4),
  (75, 3);

INSERT INTO genres (id, slug, name) VALUES
  (1, 'horror', 'Хоррор'), (2, 'indi', 'Инди'), (3, 'golovolomka', 'Головоломка'),
  (4, 'syuzhetnaya', 'Сюжетная'), (5, 'rolevaya', 'Ролевая'), (6, 'vyzhivaniya', 'Выживания'),
  (7, 'vid-sverhu', 'Вид сверху'), (8, 'zombi', 'Зомби'), (9, 'otkrytyy-mir', 'Открытый мир'),
  (10, 'pesochnitsa', 'Песочница'), (11, 'ekshen', 'Экшен'), (12, 'mmo', 'MMO'),
  (13, 'fantastika', 'Фантастика'), (14, 'kooperativ', 'Кооператив'), (15, 'simulyator', 'Симулятор'),
  (16, 'fentezi', 'Фэнтези'), (17, 'parkur', 'Паркур'), (18, 'shuter', 'Шутер'),
  (19, 'metroidvaniya', 'Метроидвания'), (20, 'dinozavry', 'Динозавры'), (21, 'vestern', 'Вестерн'),
  (22, 'pvp', 'PvP'), (23, 'kraft', 'Крафт'), (24, 'postapokalipsis', 'Постапокалипсис'),
  (25, 'souls-like', 'Souls-like'), (26, 'yaponiya', 'Япония'), (27, 'kiberpank', 'Киберпанк'),
  (28, 'roglayk', 'Роглайк'), (29, 'platformer', 'Платформер'), (30, 'priklyuchenie', 'Приключение'),
  (31, 'skandinavskaya-mifologiya', 'Скандинавская мифология'), (32, 'temnoe-buduschee', 'Тёмное будущее'),
  (33, 'kosmos', 'Космос'), (34, 'poshagovaya', 'Пошаговая'), (35, 'podvodnyy-mir', 'Подводный мир'),
  (36, 'istoriya', 'История'), (37, 'ekstrakshen', 'Экстракшен'), (38, 'fizika', 'Физика'),
  (39, 'komediya', 'Комедия'), (40, 'vampiry', 'Вампиры'), (41, 'takticheskiy', 'Тактический'),
  (42, 'pvpve', 'PvPvE'), (43, 'geroyskiy', 'Геройский'), (44, 'realizm', 'Реализм'),
  (45, 'detektiv', 'Детектив'), (46, 'kartochnaya', 'Карточная'), (47, 'dobycha', 'Добыча'),
  (48, 'piraty', 'Пираты'), (49, 'strategiya', 'Стратегия');

INSERT INTO game_genres (game_id, genre_id) VALUES
  (1, 1), (1, 2), (1, 3), (1, 4), (2, 5), (2, 6), (2, 2), (2, 7), (2, 8), (2, 9), (2, 10), (3, 11), (3, 12),
  (3, 13), (3, 14), (4, 6), (4, 2), (4, 15), (4, 4), (5, 12), (5, 5), (5, 16), (5, 9), (6, 5), (6, 4), (6, 9),
  (6, 16), (7, 11), (7, 6), (7, 8), (7, 17), (7, 14), (8, 15), (8, 5), (8, 2), (8, 14), (9, 18), (9, 11),
  (9, 13), (10, 12), (10, 5), (10, 9), (10, 16), (11, 19), (11, 2), (11, 11), (11, 4), (12, 6), (12, 12),
  (12, 9), (12, 20), (13, 11), (13, 4), (13, 9), (13, 21), (14, 11), (14, 5), (14, 14), (14, 16), (15, 6),
  (15, 12), (15, 22), (15, 23), (16, 18), (16, 4), (16, 24), (16, 9), (17, 11), (17, 4), (17, 25), (17, 26),
  (18, 5), (18, 18), (18, 9), (18, 27), (19, 28), (19, 11), (19, 2), (19, 4), (20, 14), (20, 29), (20, 30),
  (21, 6), (21, 14), (21, 9), (21, 31), (22, 12), (22, 5), (22, 9), (22, 22), (23, 18), (23, 13), (23, 14),
  (23, 22), (24, 11), (24, 5), (24, 25), (24, 9), (25, 30), (25, 2), (25, 27), (25, 3), (26, 18), (26, 14),
  (26, 11), (26, 32), (27, 5), (27, 4), (27, 14), (27, 16), (28, 14), (28, 1), (28, 2), (28, 6), (29, 5),
  (29, 18), (29, 33), (29, 9), (30, 18), (30, 14), (30, 11), (30, 13), (31, 6), (31, 14), (31, 23), (31, 9),
  (32, 12), (32, 5), (32, 22), (32, 16), (33, 11), (33, 5), (33, 14), (33, 9), (34, 14), (34, 30), (34, 13),
  (35, 5), (35, 34), (35, 4), (35, 16), (36, 6), (36, 12), (36, 9), (36, 13), (37, 18), (37, 11), (37, 16),
  (37, 4), (38, 6), (38, 14), (38, 35), (38, 13), (39, 1), (39, 6), (39, 18), (39, 4), (40, 11), (40, 25),
  (40, 14), (40, 26), (41, 28), (41, 11), (41, 2), (41, 4), (42, 19), (42, 11), (42, 2), (42, 4), (43, 11),
  (43, 25), (43, 14), (43, 28), (44, 5), (44, 4), (44, 9), (44, 36), (45, 18), (45, 37), (45, 14), (45, 13),
  (46, 14), (46, 6), (46, 30), (46, 2), (47, 14), (47, 1), (47, 2), (47, 38), (48, 30), (48, 4), (48, 39),
  (48, 2), (49, 14), (49, 1), (49, 2), (49, 39), (50, 6), (50, 5), (50, 9), (50, 40), (51, 18), (51, 41),
  (51, 9), (51, 42), (52, 18), (52, 14), (52, 43), (52, 22), (53, 18), (53, 14), (53, 11), (53, 13), (54, 18),
  (54, 11), (54, 14), (54, 32), (55, 6), (55, 30), (55, 1), (55, 2), (56, 6), (56, 14), (56, 9), (56, 1),
  (57, 1), (57, 14), (57, 6), (57, 11), (58, 18), (58, 41), (58, 14), (58, 44), (59, 1), (59, 4), (59, 18),
  (59, 45), (60, 12), (60, 5), (60, 11), (60, 16), (61, 1), (61, 6), (61, 2), (61, 4), (62, 18), (62, 14),
  (62, 1), (62, 41), (63, 18), (63, 14), (63, 8), (63, 11), (64, 46), (64, 1), (64, 2), (64, 3), (65, 18),
  (65, 14), (65, 47), (65, 13), (66, 1), (66, 14), (66, 2), (66, 45), (67, 30), (67, 12), (67, 14), (67, 48),
  (68, 18), (68, 42), (68, 1), (68, 14), (69, 5), (69, 45), (69, 4), (69, 2), (70, 11), (70, 4), (70, 13),
  (70, 19), (71, 14), (71, 30), (71, 4), (71, 11), (72, 49), (72, 6), (72, 4), (72, 15), (73, 6), (73, 33),
  (73, 9), (73, 30), (74, 12), (74, 5), (74, 4), (74, 16), (75, 12), (75, 5), (75, 14), (75, 16);

INSERT INTO trailers (game_id, name, hls_url, poster_url) VALUES
  (
    1, 'Sara Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/3576940/534399409/9562a555ac66c8ac04d83ba04a086419fe478117/1780416768/hls_264_master.m3u8?t=1780417439',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257110652/aa27df826c7a15ddf68fe12982d987c7cf6d3215/movie_600x337.jpg?t=1780417439'
  ),
  (
    2, 'Build 42 Zomboid Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/108600/619982392/141cfd121ea068a87c023951bdbfee87ca524de1/1785320937/hls_264_master.m3u8?t=1785324122',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257387571/7413640d5700fc7020002682b958233c04463d0e/movie_600x337.jpg?t=1785324122'
  ),
  (
    3, 'Warframe | Iceblade of Narin Official Gameplay Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/230410/348086520/d6e17c3aee1de563dbecba09123fcb67e2022218/1790103841/hls_264_master.m3u8?t=1790176464',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257431925/67dce112c7f567e9cff0098761191be99ea23181/movie_600x337.jpg?t=1790176464'
  ),
  (
    4, 'Gameplay Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/282070/424626/6ac5385b9c9a4a7d781b0a408e7d739999cc694a/1750489186/hls_264_master.m3u8?t=1685354286',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256864956/movie.293x165.jpg?t=1685354286'
  ),
  (
    5, 'Season Two Tomes',
    'https://video.akamai.steamstatic.com/store_trailers/306130/1481873866/8ae67bdf3b0df9dc9eb0e39e0bb2ad9bb444bed0/1792606867/hls_264_master.m3u8?t=1792607366',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257473006/e7c169b0e3fb63c8cc1ff66632f42743c125ad30/movie_600x337.jpg?t=1792607366'
  ),
  (
    6, 'The Witcher 3: Wild Hunt — Remastered | Official Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/292030/511051216/5bbe135e5caf9dce45b1fb09a9d76373fb8977b8/1790683068/hls_264_master.m3u8?t=1790693334',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257439639/32f72964eceaa2ea37c3ab03dff903a45414a89b/movie_600x337.jpg?t=1790693334'
  ),
  (
    7, 'DL SE Rework',
    'https://video.akamai.steamstatic.com/store_trailers/239140/698096/dd7e6951d39ca12b2704b24e370e01e2efec03cf/1750483635/hls_264_master.m3u8?t=1715275593',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257022021/movie.293x165.jpg?t=1715275593'
  ),
  (
    8, 'Stardew Valley Trailer 1080p',
    'https://video.akamai.steamstatic.com/store_trailers/413150/336433/0058de516bf7c46986ba1e81172ffd3c2ca6cad7/1750527541/hls_264_master.m3u8?t=1754692862',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256815967/movie.293x165.jpg?t=1754692862'
  ),
  (
    9, 'DOOM Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/379720/58691/954a3b4e4cfc0e0015a79e5316b66f49a82edd83/1750521227/hls_264_master.m3u8?t=1462985736',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256664074/movie.293x165.jpg?t=1462985736'
  ),
  (
    10, '[EN] Agent Main Combat Video ',
    'https://video.akamai.steamstatic.com/store_trailers/582660/2060383986/aa8bca8c195380cedf246af994daac729032b820/1785375029/hls_264_master.m3u8?t=1786645005',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257388073/5ab479da8f76d5e668fcbba8ca88e606c97dd699/movie_600x337.jpg?t=1786645005'
  ),
  (
    11, 'Release Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/367520/89922/b71b6a50e9aa2334fddca8fa2197cb26a3640832/1750517691/hls_264_master.m3u8?t=1497589417',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256679401/movie.293x165.jpg?t=1497589417'
  ),
  (
    12, 'ARK: Ultimate Survivor Edition Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/346110/372586/b23204cd58f68c42a07248e8472b9296c1c875c5/1750513376/hls_264_master.m3u8?t=1622089232',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256836250/movie.293x165.jpg?t=1622089232'
  ),
  (
    13, 'RDR2 Launch Trailer (US)',
    'https://video.akamai.steamstatic.com/store_trailers/1174180/254050/b2cc520c692391e65f2d09067f95001dcf4b434d/1750634049/hls_264_master.m3u8?t=1574881964',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256767979/movie.293x165.jpg?t=1574881964'
  ),
  (
    14, '191128_防衛隊派生武器_English_US_STEAM版',
    'https://video.akamai.steamstatic.com/store_trailers/582010/255950/5dffee8057c4005eb9c3f7c6443b16a42b58f208/1750555191/hls_264_master.m3u8?t=1578591085',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256769024/movie.293x165.jpg?t=1578591085'
  ),
  (
    15, 'Official Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/252490/102019/c573f5b01317174c7ae20a0abbcc3a39ccad32c2/1750487766/hls_264_master.m3u8?t=1699598112',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256684736/movie.293x165.jpg?t=1699598112'
  ),
  (
    16, 'Metro Enhanced Uncovered - ESRB',
    'https://video.akamai.steamstatic.com/store_trailers/412020/367730/d12ab0a984d079921fa2463d5ebfb0b65a65865e/1750530039/hls_264_master.m3u8?t=1622105839',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256833670/movie.293x165.jpg?t=1622105839'
  ),
  (
    17, 'Sekiro™: Shadows Die Twice - Game of the Year Edition',
    'https://video.akamai.steamstatic.com/store_trailers/814380/322401/63cf1fdf9c16536f04b08a5b1939909f7a99a340/1750586450/hls_264_master.m3u8?t=1603837979',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256806899/movie.293x165.jpg?t=1603837979'
  ),
  (
    18, 'Cyberpunk 2077 | Broken Dreams | Edgerunners 2 Update Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1091500/319068602/a0e7ceceecf759bf446feac0658b6fe58a970b94/1792676918/hls_264_master.m3u8?t=1792682497',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257474176/d3648c90317ee936369fd886a02a0f54c0a86395/movie_600x337.jpg?t=1792682497'
  ),
  (
    19, 'Hades - v1.0 Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1145360/312686/b0312c49135823cc34946e98148abfb8da71f0fb/1750627549/hls_264_master.m3u8?t=1600353465',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256801252/movie.293x165.jpg?t=1600353465'
  ),
  (
    20, 'Official Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1426210/356092/0165ad2494097e40af29c015e8948175c3fb97a8/1750688156/hls_264_master.m3u8?t=1616514535',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256827093/movie.293x165.jpg?t=1616514535'
  ),
  (
    21, '1.0 Out Now',
    'https://video.akamai.steamstatic.com/store_trailers/892970/1773403435/2417a8f159c3b08912ee0c08e6a78d70452a083f/1788934690/hls_264_master.m3u8?t=1788958575',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257420513/3f5dcfbddfe4cca65abe94a03a46b3b5546c46ab/movie_600x337.jpg?t=1788958575'
  ),
  (
    22, 'New World: Aeternum - Gameplay Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1063730/770167/dead34555cf12a4f878da2ce935ae9aed8286c46/1750611569/hls_264_master.m3u8?t=1761755689',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257064014/8a3f3d54a0d923c731968a97eadbd58019ead07a/movie_600x337.jpg?t=1761755689'
  ),
  (
    23, 'Infinite',
    'https://video.akamai.steamstatic.com/store_trailers/1240440/936278492/afe04d9d8aea3317306d85b8383b8ad98787b2eb/1763417086/hls_264_master.m3u8?t=1763576586',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257233551/cbe4b6bb9faefe71ecfeaacce6911d206db5d9c9/movie_600x337.jpg?t=1763576586'
  ),
  (
    24, 'ELDEN RING - Accolades Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1245620/468143/7a6be00f78fb0fd8b419e92cea72cc4a19ec45f8/1750650501/hls_264_master.m3u8?t=1716311566',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256889452/movie.293x165.jpg?t=1716311566'
  ),
  (
    25, 'STRAY | Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1332010/480740/52e229bcff026b75925b610c8304660aba39c33a/1750673003/hls_264_master.m3u8?t=1658250380',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256896952/movie.293x165.jpg?t=1658250380'
  ),
  (
    26, 'Skitarii Class Reveal ',
    'https://video.akamai.steamstatic.com/store_trailers/1361210/567937892/148328fee2d70180c9b243aafa62f76024b4e0bc/1779381209/hls_264_master.m3u8?t=1779381547',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257340898/24f17461956c49be254463506264ff810a323bba/movie_600x337.jpg?t=1779381547'
  ),
  (
    27, 'Baldur''s Gate 3 - Accolades Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1086940/637951/59ca25b847b0e471638d1e2474acf71b068d57f0/1750615003/hls_264_master.m3u8?t=1702007645',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256987424/movie.293x165.jpg?t=1702007645'
  ),
  (
    28, 'Lethal Company - Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1966720/593018/d94ebe61f51f602028df99031bafd2ae075b1132/1750743020/hls_264_master.m3u8?t=1690909590',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256961309/movie.293x165.jpg?t=1690909590'
  ),
  (
    29, 'Free Lanes Update',
    'https://video.akamai.steamstatic.com/store_trailers/1716740/1715467803/6c43957e8c847d5445cfd951f9ca1b0e3176b79d/1773679572/hls_264_master.m3u8?t=1775574003',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257304516/a1c476a2c5a0acaec3b89551aab73988baec78a9/movie_600x337.jpg?t=1775574003'
  ),
  (
    30, 'Devoid of Liberty',
    'https://video.akamai.steamstatic.com/store_trailers/553850/97059895/43cbd15ee5e1bd1be5aef57dd4a093d448e2d7f5/1788431043/hls_264_master.m3u8?t=1788431411',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257416388/40bb356adaabd25fd73488264840abe84ac84718/movie_600x337.jpg?t=1788431411'
  ),
  (
    31, 'Palworld 1.0 Official Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1623730/1248102289/5810f9197a1aa0ad560333997b04947d443c7bcd/1783607226/hls_264_master.m3u8?t=1783652949',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257373728/7e13113e161160ac94f46ef35ac809e374f7ab7e/movie_600x337.jpg?t=1783652949'
  ),
  (
    32, 'Throne and Liberty - The Frozen Divide: Nix Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2429640/724984210/0a3d5291854ed421043b85b8c2c52b1da3599945/1782378835/hls_264_master.m3u8?t=1782380545',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257365336/882e9ed3c629b0912614aac779c256a656f73eb0/movie_600x337.jpg?t=1782380545'
  ),
  (
    33, '08_MHWilds_TU4.5_Multi_EN-US_ESRB_1080p',
    'https://video.akamai.steamstatic.com/store_trailers/2246340/1302522023/a82634e9f0d94dfa8714df0f49eb06b52f1d4141/1770702331/hls_264_master.m3u8?t=1770710675',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257283350/f56fc8e58afb3467141df79a3f449fab20649949/movie_600x337.jpg?t=1770710675'
  ),
  (
    34, 'Split Fiction | Official Accolades Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2001120/854995/3730871b30a32f17510f03e0dc85913eccb0186b/1748810947/hls_264_master.m3u8?t=1742494046',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257116893/b4bbd6dc66f4d060be19939f12fa52593c01b5b8/movie_600x337.jpg?t=1742494046'
  ),
  (
    35, 'Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1903340/876247/5c4709c3a98d932003a6b85bd5e4bfcd6a777e7a/1748581603/hls_264_master.m3u8?t=1745478082',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257129803/a409d62da478b6b9fdceeb05a1281805fe7a0dae/movie_600x337.jpg?t=1745478082'
  ),
  (
    36, 'Dune: Awakening - Console and Single Player Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1172710/1254541118/230fcc106f8bd5be4b0ebd1d8b9e62e77c5997fc/1789562842/hls_264_master.m3u8?t=1789646418',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257426522/9736a4e162986e6b38faf0d2dcb1e1164641dcbb/movie_600x337.jpg?t=1789646418'
  ),
  (
    37, 'Revelations Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/3017860/1719368325/d3698c600d70bfb1ccc00054f681ac1c52a1da76/1780926238/hls_264_master.m3u8?t=1780927893',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257352127/d1667d69102a5d2d16814f666e4691e3595860c9/movie_600x337.jpg?t=1780927893'
  ),
  (
    38, 'Subnautica 2 - Early Access Cinematic Trailer ',
    'https://video.akamai.steamstatic.com/store_trailers/1962700/1862467419/5631393dd23dad76bcb0c7917c2f60891948158a/1776997487/hls_264_master.m3u8?t=1779930098',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257323188/0ad616f54f199f3fbccec9b1a90e909fce31a1ec/movie_600x337.jpg?t=1779930098'
  ),
  (
    39, '07_RE9_LaunchPV_Multi_US_FullHD_ESRB.mp4',
    'https://video.akamai.steamstatic.com/store_trailers/3764200/348509258/64a7996bdd071550d0ca81f57b6474e3e6c954e1/1771907913/hls_264_master.m3u8?t=1772168374',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257293410/39f26816e534d08c0e80fb56ee91ad169920fd1f/movie_600x337.jpg?t=1772168374'
  ),
  (
    40, 'Nioh 3 - Accolades Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/3681010/156602689/7779c85f5dbce3c97f70477ec732ed38447e7cad/1771561265/hls_264_master.m3u8?t=1771565584',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257290844/1fb7be8a9be67d3c478e5ceddac42a0ac34087f0/movie_600x337.jpg?t=1771565584'
  ),
  (
    41, 'Hades II – v1.0 Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1145350/1067641820/dfba9c6a8b09f5bd9b323d6e699ac685065b93d3/1758924611/hls_264_master.m3u8?t=1758942439',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257204779/2f6767807df172946f5d638093dcc1c933eb24bb/movie_600x337.jpg?t=1758942439'
  ),
  (
    42, 'Release Trailer English',
    'https://video.akamai.steamstatic.com/store_trailers/1030300/970174968/f2c514c96548048dd1dca6ef500877916b75fe5a/1755841475/hls_264_master.m3u8?t=1764916585',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257186996/ac1c4277feccd41b0866ffec5d0d40b605df1851/movie_600x337.jpg?t=1764916585'
  ),
  (
    43, 'ELDEN RING NIGHTREIGN The Forsaken Hollows - Official Gameplay Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2622380/2145248185/0188086733118d0a25281444c072fc11d7d9f4ab/1764807393/hls_264_master.m3u8?t=1764808747',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257230865/3e56e8cb70503a7b33c5c696685c3fd956c5f7fd/movie_600x337.jpg?t=1764808747'
  ),
  (
    44, 'Kingdom Come: Deliverance II - Royal Edition Launch Trailer ESRB',
    'https://video.akamai.steamstatic.com/store_trailers/1771300/2110181637/b2ff0da17bc0fe1c6e3a2506ee452c4a8a86f23f/1762856877/hls_264_master.m3u8?t=1762876531',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257229489/ae4e58530a3c69ec0fbff0dc759f8f32e3dcb554/movie_600x337.jpg?t=1762876531'
  ),
  (
    45, 'ABC Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1808500/1688567022/8ecb330fb51867a492cf9436054ef4a9ed45a3af/1762957801/hls_264_master.m3u8?t=1764583045',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257230049/5e5ff0f6856abe9b4a8200dfae19d6ec5ff6e67d/movie_600x337.jpg?t=1764583045'
  ),
  (
    46, 'The Final Ascent Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/3527290/1585242327/11b9dd1a0e2f05f7ed3e22255990a2293bacb8b9/1786469033/hls_264_master.m3u8?t=1786470570',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257396692/597dac56dabc913f8de2529a22461825f4086154/movie_600x337.jpg?t=1786470570'
  ),
  (
    47, 'Sunstone Update Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/3241660/524147145/e327ae080f1f4d19bac40fccf79b876ae3ba29a2/1793192328/hls_264_master.m3u8?t=1793278961',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257482520/dc5b62a0a70918fdd661c8d948f2858378abd5cf/movie_600x337.jpg?t=1793278961'
  ),
  (
    48, 'Reveal Trailer | Extended Cut',
    'https://video.akamai.steamstatic.com/store_trailers/2592160/785131/02f08f87bb165f1791b6b248e0fbc62f39754716/1750934476/hls_264_master.m3u8?t=1743631114',
    ''
  ),
  (
    49, 'Content Warning Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2881650/681656/73819bb7ec815170d38d53a7c0267441852bc4c5/1750821037/hls_264_master.m3u8?t=1711987141',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257012412/movie.293x165.jpg?t=1711987141'
  ),
  (
    50, 'V Rising Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1604030/695563/ec1d7936ac8aac583439039a89a421f9ab70fb0b/1750710266/hls_264_master.m3u8?t=1714748047',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257020634/movie.293x165.jpg?t=1714748047'
  ),
  (
    51, 'Gray Zone Warfare Rundown Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2479810/51791228/1f35d77092712072b40beaddba6beb6194f14328/1788605408/hls_264_master.m3u8?t=1788767874',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257417748/51f938396ce5f47c6d522a05e9393c0c986ad520/movie_600x337.jpg?t=1788767874'
  ),
  (
    52, 'Path to Doomsday - Avengers: Infinity War | New PvP Mode Trailer | Marvel Rivals',
    'https://video.akamai.steamstatic.com/store_trailers/2767030/838245032/e9ce45a69f675a9b5580cd75e84610098c4c9d0c/1791528757/hls_264_master.m3u8?t=1791536404',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257453703/c8377c6710a6226952a19c8663b807987b264090/movie_600x337.jpg?t=1791536404'
  ),
  (
    53, 'Raven Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2074920/1277952417/31a529c9f8546142a8abc0d34c338ee6b2f1048c/1787050953/hls_264_master.m3u8?t=1787211275',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257402185/64c7e3b83b2ec04675ef3bd999c83173d28c549d/movie_600x337.jpg?t=1787211275'
  ),
  (
    54, 'Warhammer 40,000: Space Marine 2 - Anniversary Update II Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/2183900/2007785104/cd2a8a592bc18a44f4fddc7b61030ab1c24cd4d4/1790765090/hls_264_master.m3u8?t=1790873219',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257440872/9569786b7628acdc9d5561f445d804bd584b883d/movie_600x337.jpg?t=1790873219'
  ),
  (
    55, 'Pacific Drive - 2023 Gameplay Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1458140/537096/6175980df1ad0a369f0150579ed0ef146d53c373/1750691469/hls_264_master.m3u8?t=1683140284',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256929444/movie.293x165.jpg?t=1683140284'
  ),
  (
    56, 'Sons Of The Forest Multiplayer Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1326470/541725/76f298f949c4ae5b4257fa2056112f8d34285799/1750672622/hls_264_master.m3u8?t=1677175226',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256932123/movie.293x165.jpg?t=1677175226'
  ),
  (
    57, 'Project Boneyard',
    'https://video.akamai.steamstatic.com/store_trailers/1304930/652862718/0c8922ff5de45cd40b1a164133f29937b70758f4/1784061974/hls_264_master.m3u8?t=1784123706',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257377059/6fd5b12b6466d4ad31e7772b40bd506ae0c9bde4/movie_600x337.jpg?t=1784123706'
  ),
  (
    58, 'Are you Ready?',
    'https://video.akamai.steamstatic.com/store_trailers/1144200/638244/12f8bb50a5d59521ffec9607bd2b6df0ae6b16a5/1750627363/hls_264_master.m3u8?t=1702510541',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256987629/movie.293x165.jpg?t=1702510541'
  ),
  (
    59, 'TheLastCowboy',
    'https://video.akamai.steamstatic.com/store_trailers/1087100/225388/10e6ad9e2f858d496ab07072f25944e3715b3b22/1751186527/hls_264_master.m3u8?t=1559042695',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256751883/movie.293x165.jpg?t=1559042695'
  ),
  (
    60, 'Lost Ark - Kazeros Raid',
    'https://video.akamai.steamstatic.com/store_trailers/1599340/2015650307/071f941b44b56e474e01696809d644af4bc8a3e0/1763505839/hls_264_master.m3u8?t=1763571522',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257234113/b31879d9976fdd5ba9eff54ea02c4822fca1a18d/movie_600x337.jpg?t=1763571522'
  ),
  (
    61, 'Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1262350/508824/c82cb1f2353e146970c0255ecdf6337bdc7d4079/1750657178/hls_264_master.m3u8?t=1666887901',
    ''
  ),
  (
    62, 'GTFO Rundown 8.0 Duality',
    'https://video.akamai.steamstatic.com/store_trailers/493520/638800/e4527451711c1f46bf2a578788583904b5bd5495/1750537589/hls_264_master.m3u8?t=1702229106',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256987944/movie.293x165.jpg?t=1702229106'
  ),
  (
    63, 'Back 4 Blood Expansion 3 Trailer ESRB',
    'https://video.akamai.steamstatic.com/store_trailers/924970/519587/d2f6295b37f0962560c808d6fd35b7da74fdf333/1750596829/hls_264_master.m3u8?t=1670349690',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256919552/movie.293x165.jpg?t=1670349690'
  ),
  (
    64, 'Inscryption - Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1092790/302287/ab0d21c6b888e99deba7fb8ca48e0f34ebba0332/1750618102/hls_264_master.m3u8?t=1597161792',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256795106/movie.293x165.jpg?t=1597161792'
  ),
  (
    65, 'Season 06 - Release Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/548430/1912821037/a9a4174ee3e32773076b9f64e2f27cd7627bdbed/1769597323/hls_264_master.m3u8?t=1769688641',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257274503/ec01dd9ef60548cf523dccbc407eacd472eae374/movie_600x337.jpg?t=1769688641'
  ),
  (
    66, 'Willow Rework Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/739630/1110188961/d019d6795771dfe079d656ff9d286eb8eddd59e4/1784635068/hls_264_master.m3u8?t=1784637252',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257381662/d2c6bdf4f9ef5d20a9f17a67da33c2aaf871d0ab/movie_600x337.jpg?t=1784637252'
  ),
  (
    67, 'Sea of Thieves: 2026 Edition Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/1172620/2026344220/6ebc4b13a13791d3a614b638e75ebf3fe1bd9f5d/1774018273/hls_264_master.m3u8?t=1775747047',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257306747/795fd3448e5c8777a744f224664d3a9664e86ea1/movie_600x337.jpg?t=1775747047'
  ),
  (
    68, 'Hunt: Showdown 1896 - Blood Testament_Bloodskin',
    'https://video.akamai.steamstatic.com/store_trailers/594650/772038488/18d9f0d8f0500684cf2b424b3fa6c22031c74d7d/1789132874/hls_264_master.m3u8?t=1789157484',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257422558/947d3bb2e7f7c2e7705fb29b3ce10b4ced4625c7/movie_600x337.jpg?t=1789157484'
  ),
  (
    69, 'Disco Elysium - The Final Cut - Launch Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/632470/357391/40d4d0a212158209daf4efe0c8d98f90c1322e1b/1750564395/hls_264_master.m3u8?t=1617123094',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256827872/movie.293x165.jpg?t=1617123094'
  ),
  (
    70, 'Control Ultimate Edition Trailer (Eng ESRB)',
    'https://video.akamai.steamstatic.com/store_trailers/870780/302947/a9fd4106f169a2a8828160ffbfa16aadd7fea059/1750591905/hls_264_master.m3u8?t=1599146533',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256795524/movie.293x165.jpg?t=1599146533'
  ),
  (
    71, 'AWO GamePlay',
    'https://video.akamai.steamstatic.com/store_trailers/1222700/293798/237b334d34624a0fb368eec79be37d17f0bde91b/1750644757/hls_264_master.m3u8?t=1592600313',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256790157/movie.293x165.jpg?t=1592600313'
  ),
  (
    72, 'Final Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/323190/553817/d7f470c4d5519f83e39504df2c22449dc3ee6974/1750508483/hls_264_master.m3u8?t=1685028532',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256938862/movie.293x165.jpg?t=1685028532'
  ),
  (
    73, 'No Man''s Sky FORSAKEN Trailer',
    'https://video.akamai.steamstatic.com/store_trailers/275850/1065580902/ecef9b2be8d1a8b272abbafa6dbf4cc1067ccdd0/1793179247/hls_264_master.m3u8?t=1793196384',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257482185/fe075d4a8c66267937ce4b1296d73d0a317383db/movie_600x337.jpg?t=1793196384'
  ),
  (
    74, 'FINAL FANTASY XIV Online in 1 Minute',
    'https://video.akamai.steamstatic.com/store_trailers/39210/613979/88ac5a485766def3cf797e9619dc9ca4c1fbacc8/1750485336/hls_264_master.m3u8?t=1696525764',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/256973188/movie.293x165.jpg?t=1696525764'
  ),
  (
    75, 'GW2_Steam_Evergreen_Trailer_2024_EN_ESRB',
    'https://video.akamai.steamstatic.com/store_trailers/1284210/784871/f5234afe412500e7b642ada37fb67a65240cbd8a/1750663488/hls_264_master.m3u8?t=1731549751',
    'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/257072840/c2cf226649a223576fca3a9c58be76da341f7bd5/movie_600x337.jpg?t=1731549751'
  );

INSERT INTO favorites (user_id, game_id) VALUES
  (1, 1), (1, 41), (1, 21);

INSERT INTO feedback (id, user_id, name, email, phone, contact, topic, message, status, created_at, answered_at) VALUES
  (
    1, 1, 'demo', 'demo@indieforge.local', '', 'demo@indieforge.local', 'Сайт',
    'где находятся системные требования игр?', 'answered', NOW() - INTERVAL 44 HOUR, NOW() - INTERVAL 41 HOUR
  ),
  (
    2, NULL, 'megamefa', 'megamefa@example.com', '', 'megamefa@example.com', 'Моды',
    'почему не качается мод с сайта?', 'new', NOW() - INTERVAL 19 HOUR, NULL
  ),
  (
    3, NULL, 'шабака', 'shabaka@example.com', '', 'Telegram: @shabaka', 'Сайт',
    'как добавить своё видео на фон профиля?', 'new', NOW() - INTERVAL 9 HOUR, NULL
  );

INSERT INTO feedback_replies (feedback_id, author, body, created_at) VALUES
  (
    1, 'IndieForge',
    'Требования живут на карточке каждой игры — вкладка «Системные требования». Там два списка: '
    'минимальные и рекомендуемые. Если нужной игры нет в каталоге, напишите нам — добавим.',
    NOW() - INTERVAL 41 HOUR
  );

INSERT INTO mods (id, slug, title, game_id, game_title, kicker, summary, body, engine, route, tools, status, status_label, version, compatibility, notes, cover_path, updated_label) VALUES
  (
    1, 'zomboid-hud', 'Сонарное кольцо и тихий HUD', 2, 'Project Zomboid', 'HUD · интерфейс выживания',
    'Переосмысленный интерфейс состояния: сонар вместо шкал, который показывает не цифры, а направление угрозы.',
    'Задача была простой только на бумаге: убрать с экрана десяток полосок и оставить ощущение, что '
    'персонаж действительно прислушивается к городу. Мы собрали кольцо состояния, которое реагирует '
    'на шум, температуру и усталость.\n\nВнутри — аккуратная отрисовка ISUI, собственные настройки '
    'через ModOptions и переводы. Всё сделано так, чтобы HUD не спорил с ванильным интерфейсом и не '
    'ломал сохранения при отключении.',
    'Lua / Java', 'ModOptions + ISUI', 'ZCode, Codex', 'ready', 'готов', '1.4', 'Build 42',
    'Кольцо не перекрывает инвентарь и работает в любом разрешении.\nНастройки яркости и '
    'чувствительности вынесены в отдельное меню.\nВсе строки переведены на русский и английский.',
    'assets/img/games/wide/project-zomboid.jpg', 'октябрь 2025'
  ),
  (
    2, 'portal-assets', 'Портальная пушка в чужом движке', NULL, 'Portal 2', 'Ассеты · перенос модели',
    'Модель, материалы и звуки портальной пушки, собранные заново под другой движок без потери читаемости.',
    'Перенос ассета — это не копирование файла. Нужно разобрать VPK, вытащить MDL v49, пересобрать '
    'VTF-текстуры и сохранить ощущение веса, которое задаёт оригинал.\n\nМы документировали каждый '
    'шаг: чем отличается шейдер, где теряется бамп, почему звук выстрела звучит суше. Получился не '
    'просто порт, а карта решений для похожих задач.',
    'Source', 'Обмен активами, сквозная передача', 'Codex, Crowbar', 'ready', 'готов', '0.9', 'Source SDK 2013',
    'Модель сохранена в исходной пропорции и масштабе.\nМатериалы проверены на трёх картах с разным '
    'освещением.\nЗвуковой слой собран из оригинальных сэмплов.',
    '', 'август 2025'
  ),
  (
    3, 'minecraft-pack', 'Аудит модпака 26.2', NULL, 'Minecraft', 'Сборка · диагностика',
    'Разбор большого NeoForge-модпака: конфликты конфигураций, зомби-процессы и честный замер производительности.',
    'Модпак запускался через раз и винил во всём «плохой компьютер». Мы сняли профиль загрузки и '
    'нашли три мода, которые по очереди перезаписывали одни и те же настройки.\n\nПосле чистки '
    'получился стабильный набор с понятным порядком загрузки, отключёнными дублями и списком '
    'совместимых версий. Отдельная инструкция объясняет, как не вернуть проблему после обновления.',
    'Java (Minecraft)', 'Переработка, API загрузчика, управляемый патч', 'OpenCode, Codex, Spark', 'progress',
    'в работе', '26.2-rc2', 'NeoForge 26.2',
    'Время запуска сокращено почти вдвое.\nУбраны циклические зависимости между модами.\nВедётся '
    'журнал совместимости для каждого обновления.',
    '', 'ноябрь 2025'
  ),
  (
    4, 'terraria-melee', 'Melee внутри Terraria', NULL, 'Terraria', 'Эксперимент · игра в игре',
    'Декомпилированный движок Super Smash Bros. Melee, собранный как нативная DLL для tModLoader.',
    'Самый странный проект мастерской: мы попытались запустить логику Melee внутри Terraria. Не '
    'эмулятор, а именно перенос симуляции боя с 3D-бойцами и сверкой по записям Slippi.\n\nРабота '
    'далека от релиза, но прототип уже показывает, что границы между движками существуют только до '
    'тех пор, пока вы не начнёте их измерять.',
    '.NET / XNA / FNA', 'API загрузчика, декомпозиция и рекомпозиция', 'Codex, агенты, Slippi', 'progress',
    'в работе', 'prototype', 'tModLoader 1.4.4',
    'Симуляция боя работает в изолированном окне.\nПока нет полноценного меню и выбора арены.\n'
    'Записи Slippi используются как эталон таймингов.',
    '', 'сентябрь 2025'
  ),
  (
    5, 'valheim-mjolnir', 'Мьёльнир вместо Фростнера', 21, 'Valheim', 'Геймплей · предмет',
    'Аккуратная подмена модели и эффектов: молот возвращается в руку, бьёт молнией и не ломает баланс.',
    'Хотелось не просто перекрасить Фростнер, а вернуть ему характер: тяжесть, гул перед ударом и '
    'ощущение, что оружие само решает, когда вернуться.\n\nМодель и эффекты заменены, урон оставлен '
    'в рамках ванильной вилки. Мод не трогает сохранения и отключается без последствий.',
    'Unity (Mono)', 'Управляемый патч', 'OpenCode, Codex, BepInEx', 'ready', 'готов', '1.1', 'Valheim 0.219',
    'Возврат молота работает и в мультиплеере.\nЭффекты молнии синхронизированы у всех игроков.\n'
    'Урон не выходит за пределы ванильного оружия.',
    'assets/img/games/wide/valheim.jpg', 'июль 2025'
  ),
  (
    6, 'schedule-nemesis', 'Система «Немезида»', NULL, 'Schedule I', 'Геймплей · фракции',
    'Каратели и полиция запоминают игрока: система фракций из Shadow of Mordor внутри цикла Schedule I.',
    'В Schedule I не хватало врага, который помнит вас лично. Мы добавили офицеров с именами, '
    'обидами и привычками: один приходит с собакой, другой предпочитает засады.\n\nПрогрессия '
    'сохраняется между сессиями, но не превращается в бесконечную войну. Если игрок меняет район, '
    '«Немезида» меняет маршрут.',
    'Unity (IL2CPP)', 'Управляемый патч', 'Codex, Gemini CLI', 'testing', 'тестирование', '0.6',
    'Schedule I 0.3',
    'Офицеры получают имена и короткие биографии.\nСистема не трогает экономику и основной сюжет.\n'
    'Идёт закрытый тест на сохранениях разных версий.',
    '', 'октябрь 2025'
  ),
  (
    7, 'beamng-bridge', 'Minecraft в кузове', NULL, 'BeamNG.drive', 'Мост · WebSocket',
    'Сквозная игра между BeamNG.drive и Minecraft: Стив честно едет в кузове, а физика передаётся в реальном времени.',
    'Мы хотели проверить, можно ли соединить две игры так, чтобы одна была продолжением другой. Мост '
    'на WebSocket передаёт положение, скорость и повреждения автомобиля в Minecraft.\n\nСтив не '
    'просто сидит на модели: он реагирует на ускорение и падение. Это технический этюд, но он лучше '
    'многих слов объясняет, зачем нужны открытые движки.',
    'Собственный / неизвестный', 'Сквозная игра (игра внутри игры)', 'OpenCode, Node.js', 'ready', 'готов',
    '0.3', 'BeamNG 0.35 + Minecraft 1.21',
    'Задержка передачи состояния — меньше 80 мс в локальной сети.\nПоддерживаются столкновения и '
    'опрокидывание.\nПроект не предназначен для публичных серверов.',
    '', 'июнь 2025'
  ),
  (
    8, 'stardew-coop', 'Тихий кооператив', 8, 'Stardew Valley', 'QoL · совместная игра',
    'Набор небольших правок для фермы на четверых: общий сундук, честные уведомления и меньше случайных пауз.',
    'Большие моды для Stardew Valley часто ломают уют. Мы пошли обратным путём: собрали несколько '
    'маленьких улучшений, которые убирают раздражающие мелочи, но не меняют ритм игры.\n\nОбщий '
    'сундук, понятные уведомления о сборке урожая и синхронизация смены сезона — всё опционально и '
    'отключается по одному пункту.',
    'C# / SMAPI', 'SMAPI-мод, точечные патчи', 'OpenCode, SMAPI', 'ready', 'готов', '1.0', 'Stardew 1.6',
    'Каждое улучшение можно отключить отдельно.\nМод не меняет баланс и экономику.\nПроверен на '
    'ферме с четырьмя игроками.',
    'assets/img/games/wide/stardew.jpg', 'май 2025'
  ),
  (
    9, 'bg3-dice', 'Спокойные кубики', 27, 'Baldur''s Gate 3', 'UI · доступность',
    'Меньше визуального шума в бросках: крупные числа, тихая анимация и понятная история результата.',
    'В BG3 бросок кубика — это драма. Но при повторных прохождениях анимация начинает мешать. Мы '
    'собрали режим, который оставляет драму, но убирает лишние вспышки и ускоряет чтение '
    'результата.\n\nМод рассчитан на доступность: контрастные цифры, отключаемая тряска и отдельный '
    'журнал всех бросков. Он не меняет правила, только подачу.',
    'Larian Engine', 'UI-патч, Script Extender', 'Codex, BG3SE', 'testing', 'тестирование', '0.4', 'Patch 8',
    'Отключается тряска камеры и вспышки.\nЖурнал бросков доступен в отдельной вкладке.\nПравила и сложность не меняются.',
    'assets/img/games/wide/bg3.jpg', 'ноябрь 2025'
  );

INSERT INTO settings (setting_key, setting_value) VALUES
  ('site_title', 'IndieForge'), ('advisor_endpoint', ''),
  ('catalog_note', '75 игр, 5 категорий и 9 проектов мастерской.'), ('database_version', '1.0');

CREATE OR REPLACE USER 'indieforge'@'localhost' IDENTIFIED BY 'indieforge2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON indieforge.* TO 'indieforge'@'localhost';
FLUSH PRIVILEGES;

SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE games AUTO_INCREMENT = 76;
ALTER TABLE categories AUTO_INCREMENT = 6;
ALTER TABLE genres AUTO_INCREMENT = 50;
ALTER TABLE feedback AUTO_INCREMENT = 4;
ALTER TABLE mods AUTO_INCREMENT = 10;
SET FOREIGN_KEY_CHECKS = 1;
