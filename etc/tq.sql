-- create schema if not exists `tq` default character set utf8;
-- use tq;

SET FOREIGN_KEY_CHECKS = 0;
create table if not exists `users` (
    id      integer not null auto_increment,
    guid    char(16) not null,
    pw      char(64) not null,
    api_key char(36) not null,
    name    varchar(255) not null,
    email   varchar(255) not null,
    type    char(1) not null default 'U',
    status  char(1) not null default 'T',
    description    text,
    created_by  integer not null,
    updated_by  integer not null,
    created_at  datetime not null,
    updated_at  datetime not null,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`guid`),
    UNIQUE KEY (`email`),
    CONSTRAINT `users_created_by_fk` foreign key (created_by) references users (id),
    CONSTRAINT `users_updated_by_fk` foreign key (updated_by) references users (id)
) engine = InnoDB default character set = utf8 collate utf8_bin;

insert into users (guid,pw,name,email,description,created_by,updated_by,type,status,created_at,updated_at) values ('systemuser123456','ac5249eb51046c7b106208d7f4fecba6923da378c53df280759f9f9ad9ab7f6b','SYSTEM','noone@nosuchemail.org','system user', 1, 1, 'A', 'A', now(), now());
SET FOREIGN_KEY_CHECKS = 1;

create table if not exists job_queue (
    id              integer not null auto_increment,
    created_by      integer not null,
    updated_by      integer not null,
    created_at      datetime not null,
    updated_at      datetime not null,
    host            varchar(255),
    pid             integer,
    cmd             text,
    error_msg       text,
    type            char(1),
    xid             integer,
    uuid            char(36) not null,
    schedule_dtim   datetime,
    start_dtim      datetime,
    complete_dtim   datetime,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`uuid`),
    CONSTRAINT `job_queue_created_by_fk` foreign key (created_by) references users (id),
    CONSTRAINT `job_queue_updated_by_fk` foreign key (updated_by) references users (id)
) engine = InnoDB default character set = utf8 collate utf8_bin;

create table if not exists scheduled_jobs (
    id              integer not null auto_increment,
    created_by      integer not null,
    updated_by      integer not null,
    created_at      datetime not null,
    updated_at      datetime not null,
    status          char(1) not null default 'A',
    name            varchar(255),
    description     text,
    crontab         varchar(255),  -- schedule syntax
    cmd             text,          -- must be relative to APP/bin
    uuid            char(36) not null,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`uuid`),
    CONSTRAINT `scheduled_job_created_by_fk` foreign key (created_by) references users (id),
    CONSTRAINT `scheduled_job_updated_by_fk` foreign key (updated_by) references users (id)
) engine = InnoDB default character set = utf8 collate utf8_bin;

create table if not exists media (
    id              integer not null auto_increment,
    created_by      integer not null,
    updated_by      integer not null,
    created_at      datetime not null,
    updated_at      datetime not null,
    status          char(1) not null default 'A',
    name            varchar(255),
    uri             text,
    transcript      mediumtext,
    uuid            char(36) not null,
    user_id         integer not null,
    PRIMARY KEY (`id`),
    UNIQUE KEY (`uuid`),
    CONSTRAINT `media_user_fk` foreign key (user_id) references users (id),
    CONSTRAINT `media_created_by_fk` foreign key (created_by) references users (id),
    CONSTRAINT `media_updated_by_fk` foreign key (updated_by) references users (id)
) engine = InnoDB default character set = utf8 collate utf8_bin;


