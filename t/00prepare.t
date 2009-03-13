use Test::More tests => 1;

use DBI;

my $dbh = DBI->connect("dbi:SQLite:table.db");
ok($dbh);

$dbh->do(<<"");
DROP TABLE IF EXISTS `category`;

$dbh->do(<<"");
CREATE TABLE `category` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `user_id` INTEGER,
 `title` varchar(40) default ''
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `article`;

$dbh->do(<<"");
CREATE TABLE `article` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `category_id` INTEGER,
 `comment_count` INTEGER,
 `user_id` INTEGER,
 `title` varchar(40) default '',
 `name` varchar(40) default ''
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `comment`;

$dbh->do(<<"");
CREATE TABLE `comment` (
 `master_id` INTEGER,
 `type` varchar(40) default '',
 `content` varchar(40) default '',
 PRIMARY KEY(`master_id`, `type`)
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `podcast`;

$dbh->do(<<"");
CREATE TABLE `podcast` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `user_id` INTEGER,
 `title` varchar(40) default ''
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `tag`;

$dbh->do(<<"");
CREATE TABLE `tag` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default ''
);


$dbh->do(<<"");
DROP TABLE IF EXISTS `article_tag_map`;

$dbh->do(<<"");
CREATE TABLE `article_tag_map` (
 `article_id` INTEGER,
 `tag_id` INTEGER,
 PRIMARY KEY(`article_id`, `tag_id`)
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `tree`;

$dbh->do(<<"");
CREATE TABLE `tree` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `parent_id` INTEGER,
 `title` varchar(40) default '',
 `path` varchar(40) default '',
 `level` INTEGER NOT NULL DEFAULT 0
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `user`;

$dbh->do(<<"");
CREATE TABLE `user` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `name` varchar(40) default '',
 `password` varchar(40) default '',
 UNIQUE(`name`)
);


$dbh->do(<<"");
DROP TABLE IF EXISTS `user_admin`;

$dbh->do(<<"");
CREATE TABLE `user_admin` (
 `user_id` INTEGER PRIMARY KEY,
 `beard` varchar(40) default ''
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `wiki`;

$dbh->do(<<"");
CREATE TABLE `wiki` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `user_id` INTEGER,
 `title` varchar(40) default '',
 `addtime` INTEGER,
 `revision` INTEGER DEFAULT 1
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `wiki_diff`;

$dbh->do(<<"");
CREATE TABLE `wiki_diff` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `wiki_id` INTEGER,
 `user_id` INTEGER,
 `title` varchar(40) default '',
 `addtime` INTEGER,
 `revision` INTEGER DEFAULT 1
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `wiki_simple`;

$dbh->do(<<"");
CREATE TABLE `wiki_simple` (
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `parent_id` INTEGER,
 `addtime` INTEGER NOT NULL,
 `user_id` INTEGER NOT NULL,
 `revision` INTEGER NOT NULL DEFAULT 1,
 `title` varchar(40) default '',
 `content` varchar(40) default ''
);

$dbh->do(<<"");
DROP TABLE IF EXISTS `nested_comment`;

$dbh->do(<<"");
CREATE TABLE `nested_comment` (
 `id`          INTEGER PRIMARY KEY,
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

