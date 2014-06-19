#!/usr/bin/env perl

use strict;
use warnings;
use inc::Module::Install;
use 5.008009;

name 'TQ';
version '0.001';

include 'Module::AutoInstall';

# web app
requires 'YAML::Syck';
requires 'Catalyst::Devel';
requires 'Module::Install::Catalyst';
requires 'Catalyst::Runtime' => '5.90016';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Action::RenderView';
requires 'CatalystX::RoleApplicator';
requires 'Catalyst::TraitFor::Request::ProxyBase';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Static::Simple::ByClass';
requires 'Catalyst::Authentication::Credential::HTTP';
requires 'CatalystX::CRUD'                   => '0.56';
requires 'CatalystX::CRUD::Model::RDBO'      => '0.301';
requires 'Catalyst::Controller::REST'        => 0;
requires 'CatalystX::CRUD::Controller::REST' => 0;
requires 'Catalyst::View::TT'                => 0;
requires 'Catalyst::View::Email::Template'   => 0;
requires 'Email::Sender::Simple'             => 0;
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General';
requires 'Test::More'                  => '0.88';
requires 'Algorithm::Cron'             => 0;
requires "Audio::Scan"                 => 0;
requires "Carp"                        => 1.25;
requires "Compress::Zlib"              => 2.061;
requires "Config::IniFiles"            => 2.72;
requires "Data::Dump"                  => 1.21;
requires "DateTime"                    => 0.72;
requires "DateTime::Format::W3CDTF"    => 0.06;
requires "DateTime::Format::HTTP"      => 0;
requires "DateTime::Format::DateParse" => 0;
requires "DBD::mysql"                  => 0;
requires "Digest::SHA"                 => 5.61;
requires "Email::Stuff"                => 0;
requires "Encode"                      => 2.55;
requires "File::Slurp::Tiny"           => 0;
requires "File::Temp"                  => 0.22;
requires "HTTP::Message"               => 6.06;
requires "IO::Interactive"             => "0.0.6";
requires "IPC::Cmd"                    => "0.70";
requires "JSON"                        => 2.53;
requires "Lingua::EN::Tagger";
requires "LWP::UserAgent"              => 6.05;
requires "MIME::Base64"                => 3.13;
requires "MooseX::StrictConstructor"   => 0;
requires "Parallel::Forker"            => "1.232";
requires "Path::Class"                 => 0.32;
requires "Path::Class::File::Lockable" => 0.02;
requires "Rose::DateTime::Parser"      => "0.50";
requires "Rose::DateTime"              => "0.540";
requires "Rose::DB::Object"            => 0.789;
requires "Rose::DBx::AutoReconnect"    => 0;
requires "Search::Tools"               => '1.000';
requires "SQL::SplitStatement"         => 0;
requires "Sys::Hostname"               => 1.16;
requires "Template"                    => '2.25';
requires "Term::ProgressBar::Simple";
requires "Text::CSV_XS";
requires "Try::Tiny";
requires "Unix::PID::Tiny" => 0.9;
requires "UUID::Tiny";

perl_version '5.8.9';
license 'MIT';
homepage 'https://github.com/APMG/audio-search';
bugtracker 'https://github.com/APMG/audio-search/issues';
repository 'https://github.com/APMG/audio-search';

installdeps_target();

WriteAll();
