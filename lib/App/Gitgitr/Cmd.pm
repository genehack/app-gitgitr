package App::Gitgitr::Cmd;
use Moose;
use namespace::autoclean;

extends 'MooseX::App::Cmd';

sub default_command { 'build' }

1;
