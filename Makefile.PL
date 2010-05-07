#!/usr/bin/env perl

use inc::Module::Install;

name 'App-Gitgitr';
all_from 'lib/App/Gitgitr/Cmd.pm';
githubmeta;

requires 'Archive::Extract';
requires 'Carp';
requires 'File::Remove';
requires 'FindBin';
requires 'LWP::Simple';
requires 'Moose';
requires 'MooseX::App::Cmd';
requires 'MooseX::Declare';
requires 'namespace::autoclean';

install_script glob('bin/gitgitr');
auto_install;

WriteAll;
