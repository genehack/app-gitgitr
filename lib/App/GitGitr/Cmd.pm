package App::GitGitr::Cmd;
# ABSTRACT: GitGitr command support. See 'gitgitr'.
use base 'App::Cmd::Simple';

use autodie qw/ :all /;
use strictures 1;
use strict;
use 5.010;

use Archive::Extract;
use Carp;
use File::Remove 'remove';
use LWP::Simple;

sub opt_spec {
  return (
    [ "run_tests|t" => 'run "make test" after building' ] ,
    [ "verbose|V"   => 'be verbose about what is being done' ] ,
    [ "version|v"   => 'Which git version to build. Default = most recent' ] ,
  );
}

sub execute {
  my( $self , $opt , $args ) = @_;

  my $version = $opt->{version} // _build_version();
  my $install_dir = "/opt/git-$version";

  say "CURRENT VERSION: $version"
    if $opt->{verbose};

  if ( -e $install_dir ) {
    $self->_symlink( $opt , $version );
    say "Most recent version ($version) already installed at /opt/git";
  }
  else {
    chdir( '/tmp' );

    say "BUILD/INSTALL git-$version"
      if $opt->{verbose};

    my $pkg_path = $self->_download( $opt , $version );
    $self->_extract( $opt , $pkg_path );
    $self->_configure( $opt , $version , $install_dir );
    $self->_make( $opt );
    $self->_make_test( $opt ) if $opt->{run_tests};
    $self->_make_install( $opt );
    $self->_cleanup( $opt , $version );
    $self->_symlink( $opt , $version );

    say "\n\nBuilt new git $version."
      if $opt->{verbose};
    say "New version ($version) symlinked into /opt/git";
  }

  die "No new version?!"
    unless -e "/opt/git-$version";

}

sub _build_version {
  my $content = get( 'http://git-scm.com/' );
  my( $version ) = $content =~ m|<div id="ver">v([\d\.]+)</div>|
    or croak "Can't parse version from Git web page!";
  return $version;
}

sub _download {
  my( $self , $opt , $version ) = @_;
  say "*** download" if $opt->{verbose};
  my $pkg_path = sprintf "git-%s.tar.gz" , $version;
  my $url = sprintf "http://kernel.org/pub/software/scm/git/%s" , $pkg_path;
  my $ret = getstore( $url , $pkg_path );
  die $ret unless $ret eq '200';
  return $pkg_path;
};

sub _extract {
  my( $self , $opt , $pkg_path ) = @_;
  say "*** extract" if $opt->{verbose};
  my $ae = Archive::Extract->new( archive => $pkg_path );
  $ae->extract or die $ae->error;
  unlink $pkg_path;
};

sub _configure {
  my( $self , $opt , $version , $install_dir ) = @_;
  say "*** configure" if $opt->{verbose};
  chdir "git-$version";
  ### FIXME should have some way to allow override of these args
  _run( "./configure --prefix=$install_dir --without-tcltk" );
};

sub _make {
  my( $self , $opt ) = @_;
  say "*** make" if $opt->{verbose};
  _run( 'make' );
};

sub _make_test {
  my( $self , $opt ) = @_;
  say "*** make test" if $opt->{verbose};
  _run( 'make test' );
};

sub _make_install {
  my( $self , $opt ) = @_;
  say "*** make install" if $opt->{verbose};
  _run( 'make install' );
};

sub _cleanup {
  my( $self , $opt , $version ) = @_;
  say "*** cleanup" if $opt->{verbose};
  chdir '..';
  remove( \1 , "git-$version" );
};

sub _symlink {
  my( $self , $opt , $version ) = @_;
  say "*** symlink" if $opt->{verbose};
  chdir '/opt';
  remove( 'git' );
  symlink( "git-$version" , 'git' );
};

sub _run {
  my $arg = shift;
  $arg .= ' 2>&1 >/dev/null';
  system( $arg ) == 0;
}

1;
