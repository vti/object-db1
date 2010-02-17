PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE `category` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `author_id` INTEGER,
 `title` varchar(40) default ''
);
CREATE TABLE `article` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `category_id` INTEGER,
 `author_id` INTEGER,
 `title` varchar(40) default ''
);
CREATE TABLE `comment` (
 `master_id` INTEGER,
 `type` varchar(40) default '',
 `content` varchar(40) default '',
 PRIMARY KEY(`master_id`, `type`)
);
CREATE TABLE `podcast` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `author_id` INTEGER,
 `title` varchar(40) default ''
);
CREATE TABLE `tag` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default ''
);
CREATE TABLE `article_tag_map` (
 `article_id` INTEGER,
 `tag_id` INTEGER,
 PRIMARY KEY(`article_id`, `tag_id`)
);
CREATE TABLE `author` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default '',
 `password` varchar(40) default '',
 UNIQUE(`name`)
);
CREATE TABLE `author_admin` (
 `author_id` INTEGER PRIMARY KEY,
 `beard` varchar(40) default ''
);
CREATE TABLE `nested_comment` (
 `id`          INTEGER PRIMARY KEY AUTOINCREMENT,
 `parent_id`   INTEGER,
 `master_id`   INTEGER NOT NULL,
 `master_type` VARCHAR(20) NOT NULL ,
 `path`        VARCHAR(255),
 `level`       INTEGER NOT NULL ,
 `content`     VARCHAR(1024) NOT NULL,
 `addtime`     INTEGER NOT NULL,
 `lft`         INTEGER NOT NULL,
 `rgt`         INTEGER NOT NULL
);
CREATE TABLE `family` (
 `id`          INTEGER PRIMARY KEY AUTOINCREMENT,
 `parent_id`   INTEGER,
 `name`        VARCHAR(255)
);
COMMIT;
