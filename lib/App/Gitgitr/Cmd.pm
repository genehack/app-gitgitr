package App::Gitgitr::Cmd;
use Moose;
use namespace::autoclean;
use 5.010;

extends 'MooseX::App::Cmd';

sub default_command { 'build' }

1;
