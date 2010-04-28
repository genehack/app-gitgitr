use MooseX::Declare;
class App::Gitgitr::Cmd::Command::build extends MooseX::App::Cmd::Command {
  use Archive::Extract;
  use Carp;
  use File::Remove 'remove';
  use LWP::Simple;
  use 5.010;

  has run_tests => (
    isa           => 'Bool' ,
    is            => 'rw' ,
    cmd_aliases   => 't',
    documentation => 'run "make test" after building',
    traits        => [ qw(Getopt) ] ,
    default       => 0 ,
  );

  has verbose => (
    isa           => 'Bool' ,
    is            => 'rw' ,
    cmd_aliases   => 'V' ,
    documentation => 'be verbose about what is being done' ,
    traits        => [ qw(Getopt) ] ,
    default       => 0 ,
  );

  has version => (
    isa           => 'Str' ,
    is            => 'rw'  ,
    cmd_aliases   => 'v' ,
    documentation => 'Which git version to download and build. Defaults to most current.' ,
    lazy_build    => 1 ,
    traits        => [ qw(Getopt)] ,
  );

  method _build_version {
    my $content = get( 'http://git-scm.com/' );
    my( $version ) = $content =~ m|<div id="ver">v([\d\.]+)</div>|
      or croak "Can't parse version from Git web page!";

    return $version;
  };

  has _pkg_path => (
    isa    => 'Str' ,
    is     => 'rw' ,
    traits => [ qw(NoGetopt)] ,
  );

  method execute {
    my $version = $self->version;

    say "CURRENT VERSION: $version"
      if $self->verbose;

    unless ( -e "/opt/git-$version" ) {
      chdir( '/tmp' )
        or die "Can't cd to /tmp";

      say "BUILD/INSTALL git-$version"
        if $self->verbose;

      $self->_download();
      $self->_extract();
      $self->_configure();
      $self->_make();
      $self->_make_test() if $self->run_tests;
      $self->_make_install();
      $self->_cleanup();

      say "\n\nBuilt new git $version."
        if $self->verbose;
    }

    die "No new version?!"
      unless -e "/opt/git-$version";

    $self->_symlink();

    say "New version ($version) symlinked into /opt/git";
  };

  method _download {
    say "*** download" if $self->verbose;
    $self->_pkg_path( sprintf "git-%s.tar.gz" , $self->version );
    my $url = sprintf "http://kernel.org/pub/software/scm/git/%s" , $self->_pkg_path;
    my $ret = getstore( $url , $self->_pkg_path );
    die $ret unless $ret eq '200';
  };

  method _extract {
    say "*** extract" if $self->verbose;
    my $ae = Archive::Extract->new( archive => $self->_pkg_path );
    $ae->extract or die $ae->error;
    unlink $self->_pkg_path;
  };

  method _configure {
    say "*** configure" if $self->verbose;
    my $version = $self->version;
    chdir "git-$version";
    $self->_run( "./configure --prefix=/opt/git-$version" );
  };

  method _make {
    say "*** make" if $self->verbose;
    $self->_run( 'make' );
  };

  method _make_test {
    say "*** make test" if $self->verbose;
    $self->_run( 'make test' );
  };

  method _make_install {
    say "*** make install" if $self->verbose;
    $self->_run( 'make install' );
  };

  method _cleanup {
    say "*** cleanup" if $self->verbose;
    my $version = $self->version;
    chdir '..';
    remove( \1 , "git-$version" );
  };

  method _symlink {
    say "*** symlink" if $self->verbose;
    my $version = $self->version;
    chdir '/opt';
    remove( 'git' );
    symlink( "git-$version" , 'git' );
  };

  method _run ( $arg ) {
    $arg .= ' 2>&1 >/dev/null';
    system( $arg ) == 0
      or die "$arg failed ($?)";
  };

}

__END__

=head1 NAME

App::Gitgitr::Cmd::Command::build - Fetch a git version and build it.
