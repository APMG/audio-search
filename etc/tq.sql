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

insert into users (guid,pw,name,email,description,created_by,updated_by,type,status) values ('systemuser123456','3ad9c4bf-030d-40f3-b193-bea0849ae6de','SYSTEM','noone@nosuchemail.org','system user', 1, 1, 'A', 'A');
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
    schedule_dtim   datetime,
    start_dtim      datetime,
    complete_dtim   datetime,
    PRIMARY KEY (`id`),
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
    PRIMARY KEY (`id`),
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
    uri             text,
    uuid            char(36) not null,
    user_id         integer not null,
    PRIMARY KEY (`id`),
    CONSTRAINT `media_user_fk` foreign key (user_id) references users (id),
    CONSTRAINT `media_created_by_fk` foreign key (created_by) references users (id),
    CONSTRAINT `media_updated_by_fk` foreign key (updated_by) references users (id)
) engine = InnoDB default character set = utf8 collate utf8_bin;


