#!/usr/bin/env perl
=head1 NAME

mysql_node_install.pl - registry of prepared mysql nodes

=head1 SYNOPSIS

perl mysql_node_install.pl --port=3306 --base='/opt/Percona-Server-5.6.21-rel69.0-675.Linux.x86_64' --dest='/web' --id=5

=head1 HISTORY

cz20141230 - add dynamic configuration
kc - initinal version. see https://github.com/kaiwangchen

=cut

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use POSIX qw(strftime);

my $port = 3306;
my $base = '/opt/Percona-Server-5.5.23-rel25.3-240.Linux.x86_64';
my $dest = '/web';
my $node = 'node16';
my $id   = 0;
my $verbose = 0;
my $help    = 0;

GetOptions(
    "port|p=i"    => \$port,
    "base|b=s"    => \$base,
    "dest|d=s"    => \$dest,
    "node|n=s"    => \$node,
    "id|i=i"      => \$id,
    "verbose!"    => \$verbose,
    "help|h!"     => \$help,
);

if ($help) {
    system("perldoc", "$0");
}

unless ( $port ) {
    die "node(port) should be specified."
}

my ($ver_mysql) = ($base =~ m#5\.(\d)\.#gi);
my $percona = 'Percona5' . $ver_mysql;

my %node_attr = (
    basedir => "$base",
    prefix  => "$dest/mysql/node",
    hostid  => $id,
    port    => $port,
    capabilities => ['xtradb', $percona, 'disable_query_cache', 'auto_expire_relay_log', 'bbu_raid_or_flash', 'mha_node', $node],
);

eval {
    NodeManager::MySQL->make_node(\%node_attr);
};

if ( $@ ) {
    print STDERR "+-- save failed: $@\n";
}

# ##########################################################################################
#  NodeManager::MySQL
# ##########################################################################################

package NodeManager::MySQL;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

NodeManager::MySQL - MySQL node manager

=head1 HISTORY

v0.0.1 initinal version

=cut

our $VERSION;
BEGIN {
   $VERSION = "0.0.1";
}

sub make_node {
    my( $class, $attr ) = @_;
    for ( qw(basedir prefix hostid port capabilities ) ) {
        croak "+-- $_ is required." unless $attr->{$_};
    }
    $attr->{'prepath'} = $attr->{prefix} . $attr->{port};
    my $scripts = NodeManager::MySQL::ScriptsTemplate->new($attr->{basedir}, $attr->{'prepath'});
    my $conf    = NodeManager::MySQL::ConfigTemplate->new($attr->{prefix}, $attr->{'prepath'});
    $conf->capabilities( @{$attr->{capabilities}} );
    $conf->server_id(@$attr{qw( hostid port )});

    -d $conf->nodedir or mkdir $conf->nodedir or croak("+-- can not chdir ". $conf->nodedir . ": $!");

    $class->save_readme($attr->{'prepath'});
    $scripts->save_all;
    $conf->save_cnf;

    my $df_cnf = $attr->{prepath}.'/'.'my.node.cnf';
    my $install_db = do {
        if (grep {m/Percona-Server-5\.1/i} $attr->{basedir}) {
            "./bin/mysql_install_db --user=@{[ $conf->mysqld_user ]} --defaults-file=$df_cnf --basedir=$attr->{basedir} --datadir=@{[ $conf->datadir ]}"
        } else {
            "./scripts/mysql_install_db --user=@{[ $conf->mysqld_user ]} --defaults-file=$df_cnf --basedir=$attr->{basedir} --datadir=@{[ $conf->datadir ]}"
        }
    };

    print <<"INIT_EOF"
#!/bin/bash
# use this script to initialize an empty node,
# then copy generated files into @{[ $conf->nodedir ]} on host $attr->{hostid}
set -e
mkdir -p @{[ $conf->nodedir ]}/data
chown mysql.mysql @{[ $conf->nodedir ]}/data
pushd @{[ $attr->{basedir} ]}
$install_db
popd
INIT_EOF

}

sub _save_file {
   my( $self, $fname, $method ) = @_;
   open FH, ">", $fname or die "+-- can not write $fname: $!";
   print FH $self->$method;
   close FH;
}

sub save_readme {
   my ($self, $prepath) = @_;
   $self->_save_file("$prepath/README.txt", "readme");
}

=item C<readme>

get over all description of this node manager

=cut

sub readme {
    #no strict "subs";
    my $pkg = __PACKAGE__ . "($VERSION)";
    return <<"EOF";
This is mysql node with management sripts and data directory,
 prepared by $pkg


general notes

  The scripts basically change to base directory and invoke MySQL executables
  with --defaults-file=<nodedir>/my.node.cnf as the first command line option,
  instead of reading the global /etc/my.cnf and extra files.  The scripts are
  inspired by MySQL Sandbox and the mysqld.server initrd script.

  For the sake of security, only the data directory is owned by the mysql user,
  others by root. The password file is placed in the user's home directory.

  The mysql user is usually created when mysql-server is installed, as listed 
  by 'rpm -q --scripts mysql-server':

      preinstall scriptlet (using /bin/sh):
      /usr/sbin/useradd -M -o -r -d /var/lib/mysql -s /bin/bash \
            -c "MySQL Server" -u 27 mysql > /dev/null 2>&1 || :

  Any question, contact <chenzhe07\@gmail.com>

practice notes

  Each node in the replication chain should use same config except server-id.

  socket is data/s<port>, pid file is data/mysql.pid

  scripts source noderc in the same directory to get BASEDIR setting.

  use pt-config-diff to verify my.node.cnf is consistent with the running instance

  see comments in the option file.


commands

  ./node {start|stop|status}
  ./my sqladmin status
  ./my sqlshow 
  ./my _print_defaults mysql client
  ./use
  ./use mysql
  ./use db1


resources

  http://mysqlsandbox.net/
  http://dev.mysql.com/doc/refman/5.1/en/server-system-variables.html
  http://dev.mysql.com/doc/refman/5.5/en/server-system-variables.html
  http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html
  http://www.percona.com/doc/percona-server/5.1/
  http://www.percona.com/doc/percona-server/5.5/
  http://www.percona.com/doc/percona-server/5.6/
  http://www.mysqlperformanceblog.com/2006/05/30/innodb-memory-usage/
  http://www.mysqlperformanceblog.com/2007/11/03/choosing-innodb_buffer_pool_size
  http://www.percona.com/redir/files/presentations/WEBINAR2012-03-Optimizing-MySQL-Configuration.pdf
                  
EOF
}

1;

##########################################################################################################
# NodeManager::MySQL::ScriptsTemplate
##########################################################################################################
package NodeManager::MySQL::ScriptsTemplate;

=head1 NAME

NodeManager::MySQL::ScriptsTemplate - MySQL node management scripts

=head1 SYNOPSIS

    my $scripts = NodeManager::MySQL::ScriptsTemplate->new($basedir);
    $scripts->save_all;

=head1 HISTORY

    v0.0.1 - initinal version.

=cut

use strict;
use warnings;

use base 'NodeManager::MySQL';
my %scripts;

BEGIN {
   $scripts{node} = <<'NODE_EOF';
  #!/bin/bash

  #  node management script. 
  #  start   use msyqld_safe to start slave, wait 1min and report
  #  stop    use mysqladmin to stop slave then stop node, wait until stopped
  #  status  test pid file
  #

  set -e
    
  MODE=$1
  [ $# -ge 1 ] && shift

  BASEDIR=
  NODEDIR=`dirname $0`
  echo "$NODEDIR" | grep -q '^/' || NODEDIR="`pwd`/$NODEDIR"
  NODERC="$NODEDIR/noderc"
  OPTION_FILE="$NODEDIR/my.node.cnf"

  if [ -f "$NODERC" ]
  then
      . "$NODERC"
  fi

  if [ "$BASEDIR"x = "x" ]
  then
      echo "empty BASEDIR! exit.."
      exit 1
  fi

  export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH

  # required executables
  if which pgrep >/dev/null
  then
      :
  else
      echo 'require pgrep, use "yum install procps" to install'
      exit 1;
  fi
  MYSQLD_SAFE="$BASEDIR/bin/mysqld_safe"
  if [ ! -x "$MYSQLD_SAFE" ]
  then
      echo "mysqld_safe not found in $BASEDIR/bin/"
      exit 1
  fi
  MYSQL_ADMIN="$BASEDIR/bin/mysqladmin"
  if [ ! -x "$MYSQL_ADMIN" ]
  then
      echo "mysqladmin not found in $BASEDIR/bin/"
      exit 1
  fi
  MY_PRINT_DEFAULTS="$BASEDIR/bin/my_print_defaults"
  if [ ! -x "$MY_PRINT_DEFAULTS" ]
  then
      echo "my_print_defaults not found in $BASEDIR/bin/"
      exit 1
  fi
  DEFAULTS="`$MY_PRINT_DEFAULTS --defaults-file="$OPTION_FILE" mysqld`"

  # required options
  SERVERID=`echo "$DEFAULTS" | sed -n -e '/^--server-id/s/^--server-id=//p'`
  PORT=`echo "$DEFAULTS" | sed -n -e '/^--port/s/^--port=//p'`
  DATADIR=`echo "$DEFAULTS" | sed -n -e '/^--datadir/s/^--datadir=//p'`
  PIDFILE=`echo "$DEFAULTS" | sed -n -e '/^--pid-file/s/^--pid-file=//p'`
  SOCKET=`echo "$DEFAULTS" | sed -n -e '/^--socket/s/^--socket=//p'`
  if [ "$SERVERID"x = "x" -o "$PORT"x = "x" -o "$DATADIR"x = "x" -o "$PIDFILE"x = "x" -o "$SOCKET"x = "x" ]
  then
      echo "required options: server-id port datadir pid-file socket"
      exit 1
  fi

  # server-id sanity check
  (( GUESSED_HOSTID = ( $SERVERID>>16 ) ))
  (( GUESSED_PORT  = ( $SERVERID & ((1<<15) - 1) ) ))
  if [ $PORT -ne $GUESSED_PORT -o $GUESSED_HOSTID -eq 0 ]
  then
      echo "serverid format changed: serverid $SERVERID != port $PORT + (hostid $GUESSED_HOSTID<<16)"
      exit 1
  fi

  case $MODE in
  'start' )
      MYSQLD_SAFE_OK=`sh -n $MYSQLD_SAFE 2>&1`
      if [ ! "$MYSQLD_SAFE_OK"x = "x" ]
      then
          echo "$MYSQLD_SAFE has errors"
          echo "((( $MYSQLD_SAFE_OK )))"
          exit 1
      fi

      if [ -f $PIDFILE ]
      then
          echo "node already started (found pid file $PIDFILE)"
      else
          CURDIR=`pwd`
          cd $BASEDIR
          if [ "$DEBUG_NODE"x = "x" ]
          then
              $MYSQLD_SAFE --defaults-file="$OPTION_FILE" $@ > /dev/null 2>&1 &
          else
              $MYSQLD_SAFE --defaults-file="$OPTION_FILE" $@ >> "$NODEDIR/start.log" 2>&1 &
              SAFE_PID=$!
          fi
          cd $CURDIR

          echo -n 'waiting node start '
          TIMEOUT=60
          ATTEMPTS=60
          while [ ! -s $PIDFILE ] 
          do
              ATTEMPTS=$(( $ATTEMPTS + 1 ))
              echo -n "."
              if [ $ATTEMPTS = $TIMEOUT ]
              then
                  break
              fi
              sleep 1
          done

          if [ -s $PIDFILE ]
          then
              PID=`cat "$PIDFILE"`
              echo " node on pid=$PID port=$PORT hostid=$GUESSED_HOSTID"
          else
              echo " node not started yet"
              exit 1
          fi
     fi
     ;;

 'stop' )
     if [ -s $PIDFILE ]
     then
         PID=`cat "$PIDFILE"`
         if [ -f $DATADIR/master.info ]
         then
             echo -n 'waiting slave stop '
             $MYSQL_ADMIN --defaults-file=$OPTION_FILE 'stop-slave' > /dev/null &
             ADMIN_PID=$!
             #while echo 'show slave status\G' | $MYSQL --defaults-file=$OPTION_FILE | grep -q -P 'Slave_(?:IO|SQL)_Running: Yes'
             while pgrep -P $$ 'mysqladmin' > /dev/null
             do
                 echo -n .
                 sleep 1
             done
             echo
         fi
         echo -n
         $MYSQL_ADMIN --defaults-file=$OPTION_FILE shutdown &
         ADMIN_PID=$!
         echo -n 'waiting node shutdown '
         #while [ -f $PIDFILE ] 
         while pgrep -P $$ 'mysqladmin' > /dev/null
         do
             echo -n .
             sleep 1
         done
         echo " node off pid=$PID port=$PORT hostid=$GUESSED_HOSTID"
     fi
     ;;

 'status' )
      if [ -f $PIDFILE ]
      then
          PID=`cat "$PIDFILE"`
          ON=
          if [ -n $PID ]
          then
              if kill -0 $PID
              then
                  echo "node on pid=$PID port=$PORT hostid=$GUESSED_HOSTID"
                  ON="yes"
              fi
          fi

          if [ -z $ON ]
          then
              echo "node dead pidfile=$PIDFILE"
          fi
      else
          echo "node off port=$PORT hostid=$GUESSED_HOSTID"
      fi
      ;;
  * )
      echo "Usage: $0 {start|stop|status}"
      exit 1
      ;;
  esac

NODE_EOF

    $scripts{start} = <<'WRAPPER_EOF';
  #!/bin/bash
  set -e
  "`dirname $0`/node" start
WRAPPER_EOF

    $scripts{stop} = <<'WRAPPER_EOF';
  #!/bin/bash
  set -e
  "`dirname $0`/node" stop
WRAPPER_EOF

    $scripts{status} = <<'WRAPPER_EOF';
  #!/bin/bash
  set -e
  "`dirname $0`/node" status
WRAPPER_EOF

    $scripts{'my'} = <<'MY_EOF';
  #!/bin/bash

  set -e

  if [ "$1" = "" ]
  then
      echo "syntax my sql{dump|binlog|admin} arguments"
      exit
  fi

  BASEDIR=
  NODEDIR=`dirname $0`
  echo "$NODEDIR" | grep -q '^/' || NODEDIR="`pwd`/$NODEDIR"
  NODERC="$NODEDIR/noderc"
  OPTION_FILE="$NODEDIR/my.node.cnf"

  if [ -f "$NODERC" ]
  then
      . "$NODERC"
  fi

  if [ "$BASEDIR"x = "x" ]
  then
      echo "empty BASEDIR! exit.."
      exit 1
  fi

  export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
  MYSQL=$BASEDIR/bin/mysql

  SUFFIX=$1
  shift

  MYSQLCMD="$BASEDIR/bin/my$SUFFIX"

  NODEFAULT=(myisam_ftdump
  myisamlog
  mysql_config
  mysql_convert_table_format
  mysql_find_rows
  mysql_fix_extensions
  mysql_fix_privilege_tables
  mysql_secure_installation
  mysql_setpermission
  mysql_tzinfo_to_sql
  mysql_upgrade
  mysql_waitpid
  mysql_zap
  mysqlaccess
  mysqlbinlog
  mysqlbug
  mysqldumpslow
  mysqlhotcopy
  mysqltest
  mysqltest_embedded)

  DEFAULTSFILE="--defaults-file=$OPTION_FILE"
  for NAME in ${NODEFAULT[@]}
  do
      if [ "my$SUFFIX" = "$NAME" ]
      then
          DEFAULTSFILE="--no-defaults"
          break
      fi
  done

  if [ -f $MYSQLCMD ]
  then
      exec "$MYSQLCMD" $DEFAULTSFILE "$@"
  else
      echo "$MYSQLCMD not found "
  fi
MY_EOF

    $scripts{'use'} = <<'USE_EOF';
  #!/bin/bash

  set -e

  BASEDIR=
  NODEDIR=`dirname $0`
  echo "$NODEDIR" | grep -q '^/' || NODEDIR="`pwd`/$NODEDIR"
  NODERC="$NODEDIR/noderc"
  OPTION_FILE="$NODEDIR/my.node.cnf"

  if [ -f "$NODERC" ]
  then
      . "$NODERC"
  fi

  if [ "$BASEDIR"x = "x" ]
  then
      echo "empty BASEDIR! exit.."
      exit 1
  fi

  export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
  MYSQL=$BASEDIR/bin/mysql

  if [ -f $PIDFILE ]
  then
      exec "$MYSQL" --defaults-file=$OPTION_FILE "$@"
  fi
USE_EOF

    for ( keys %scripts ) {
        # restore script content
        $scripts{$_} =~ s/^  //mg;
        no strict "refs";
        # make accessor
        *{__PACKAGE__."::$_\_script"} = sub {
            return $scripts{$_};
        };
        # make save method
        *{__PACKAGE__."::save_$_\_script"} = sub {
            shift->_save_script($_, "$_\_script");
        }
    }
}

=item C<new(basedir)>

 constructor, basedir is used to initialize noderc

=item C<node_rc>

 the BASEDIR setting to be sourced in other scripts

=item C<node_script>

 initrd like script to ease management: node {start|stop|status}

=item C<start_script>

 node start

=item C<stop_script>

 node stop

=item C<status_script>

 node status

=item C<use_script>

 quick wrapper around mysql(1)

=item C<my_script>

 quick wrapper around common MySQL executables: ./my sql{binlog|admin|dump}

=item C<save_all>

 save all scripts in current directory

=cut

sub new {
    my ( $class, $basedir, $prepath ) = @_;
    $class = ref $class || __PACKAGE__;
    bless {
        basedir => $basedir,
        prepath => $prepath,
    }, $class;
}

sub node_rc {
    my  $self  = shift @_;
    my $basedir = $self->{basedir};
    my $rc =<<"RC_EOF";
  ## defines BASEDIR required
  BASEDIR=$basedir

  ## turn on debug log
  # DEBUG_NODE = 1

RC_EOF
    $rc =~ s/^  //mg;
    return $rc;
}

sub save_node_rc {
    my $self = shift;
    $self->_save_script("noderc", "node_rc");
}

sub save_all {
    my ($self) = @_;
    $self->save_node_rc;
    no strict "refs";
    for (keys %scripts) {
        *{"save_$_\_script"}->($self);
    }
}

sub _save_script {
   my ( $self, $fname, $method ) = @_;
   $self->_save_file($self->{'prepath'} . "/" . $fname, $method);
   chmod 0755, $self->{'prepath'} . "/" . $fname;
}

1; # return true.

###############################################################################################
# NodeManager::MySQL::ConfigTemplate
###############################################################################################
package NodeManager::MySQL::ConfigTemplate;

=head1 NAME

NodeManager::MySQL::ConfigTemplate

=head1 SYNOPSIS

    my $node = NodeManager::MySQL::ConfigTemplate->new;
    $node->capabilities(qw(xtradb disable_query_cache Percona bbu_raid_or_flash));
    $node->server_id(2, 3306);

=head1 HISTORY

v0.0.1 - initinal version.

=cut

use strict;
use warnings;
use Carp;
use Data::Dumper;

use base 'NodeManager::MySQL';

use constant {
     DEFAULT_SLOT => 0,
     COMMENT => 1,
     CONDITION => 2,  # null implies required
};

our $VERSION;
BEGIN {
    $VERSION = $NodeManager::MySQL::VERSION;
}

my @node_template;

=item C<new(prefix)>

prefix, prepend to <port> to make nodedir which defaults to /web/mysql/node<port>

=cut

sub new {
    my( $class, $prefix, $prepath ) = @_;
    $prefix ||= "/web/mysql/node";
    bless {
        node => { user => 'mysql' },
        prefix => $prefix,
        prepath => $prepath,
    }, ref($class) || __PACKAGE__;
}

sub tips {
    my $self = shift @_;
    my @t = ();
    if ( $self->{server_id} ) {
        push @t, "  hostid       = " . $self->{server_id}{hostid};
        push @t, "  port         = " . $self->{server_id}{port};
    }
    if ( $self->{prefix} ) {
        push @t, "  prefix       = ".$self->{prefix};
    }
    if ( $self->{cap} ) {
        push @t, "  capabilities = " . join(" ", keys %{$self->{cap}});
    }
    return @t;
}

=item C<server_id(hostid, port)>

 hostid, must be unique number, usually taken from last section of internal ip address, 
 say, 10.0.0.2 as 2. port, must be the same in the replication chain and unique 
 among chains.

=cut

sub server_id {
    my ( $self, $hostid, $port ) = @_;
    if ( @_ > 2 ) {
        my $datadir = "$self->{prefix}$port/data";
        $self->{node}{'datadir'} = $datadir;
        $self->{node}{'socket'} = "$datadir/s$port";
        $self->{node}{'pid-file'} = "$datadir/mysql.pid";
        $self->{node}{'port'} = $port;
        $self->{node}{'syslog-tag'} = $port;

        $self->{comment}{'server-id'} = "$port+($hostid<<16)";
        $self->{node}{'server-id'} = $port + ($hostid << 16);
        $self->{server_id} = {  hostid=>$hostid, port=>$port };
    }
    $self->{node}{'server-id'};
}

=item C<capabilities(...)>

 template supported capabilities:
 innodb_plugin xtradb myisam
 disable_query_cache auto_expire_relay_log mha_node Percona51 Percona55
 bbu_raid_or_flash
 node16 node32 node48 node64

 xtradb suppresses innodb_plugin
 xtradb and innodb_plugin implies innodb
 innodb_plugin suppresses disable_query_cache
 mha_node suppresses auto_expire_relay_log
 node16 node32 node48 node64

 suggestions
  bbu_raid_or_flash
  MySIAM: myisam auto_expire_relay_log
  InnoDB: innodb_plugin auto_expire_relay_log
  Mixed: myisam innodb_plugin auto_expire_relay_log 
  XtraDB: xtradb disable_query_cache Percona55 Percona 56

=cut

sub capabilities {
    my $self = shift;
    my %known_cap = map { $_ => 1 } qw(
        innodb_plugin xtradb myisam
        auto_expire_relay_log mha_node Percona51 Percona55 Percona56
        bbu_raid_or_flash node16 node32 node48 node64
    );
    if ( @_ ) {
        $self->{cap} = { map { $_ => 1 } grep { $known_cap{$_} } @_ };
    }
    my $c = $self->{cap};
    if ( $c->{xtradb} ) {
        delete $c->{innodb_plugin};
    }
    if ( $c->{innodb_plugin} ) {
        delete $c->{Percona51};
        delete $c->{Percona55};
        delete $c->{Percona56};
        delete $c->{disable_query_cache};
    }
    if ( $c->{mha_node} ) {
        delete $c->{auto_expire_relay_log};
    }
    if ( $c->{innodb_plugin} || $c->{xtradb} ) {
        $c->{innodb} = 1;
    }
    if ( $c->{innodb} ) {
        unless ( $c->{node16} || $c->{node32} || $c->{node48} || $c->{node64} ) {
            $c->{node16} = 1;
        }
    } else {
        delete $c->{node16};
        delete $c->{node32};
        delete $c->{node48};
        delete $c->{node64};
    }
    return $c;
}

sub nodedir {
   my $self = shift;
   croak "port not intialized, should call server_id" unless $self->{node}{'port'};
   return "$self->{prefix}$self->{node}{'port'}";
}

sub datadir {
   my $self = shift;
   croak "port not intialized, should call server_id" unless $self->{node}{'port'};
   return "$self->{prefix}$self->{node}{'port'}/data";
}

sub mysqld_user {
   my $self = shift;
   return $self->{node}{user} || 'mysql';
}

sub save_cnf {
    my $self = shift;
    $self->_save_file($self->{'prepath'} . "/" . "my.node.cnf", "my_node_cnf");
}

=item C<my_node_cnf(cb,misc)>

 cb, template printer, defaults to C<populate_template>. refer to it for example.
  misc, available as $args{misc} in callback.

=cut

sub my_node_cnf {
    my ( $self, $cb, $misc ) = @_;
    my %args = (
        cap => $self->{cap},
        node => $self->{node},
        comment => $self->{comment},
        cnf => join("",
                       map { "# $_\n" }
                       "auto generated by " . __PACKAGE__ . "($VERSION), ",
                       "edit at your own risks. Template args: ",
                       $self->tips,
                   ) . "\n",
        misc => $misc,
    );
    $cb ||= \&populate_template;
    # walk the default template with customization args
    my @path = ('');
    walk_template_ex(\@path, \@node_template, $cb, \%args);
    return $args{cnf};
}

sub option_line {
    my ( $path, $key, $value, $comment, $attr, $args ) = @_;

    # non-default comment
    $comment = $args->{comment}{$key} if $args->{comment}{$key};

    my $str = "";
    my $sp = $args->{bash_syntax} ? "" : " ";
    # overwrite
    if ($args->{node}{$key}) {
        $str .= join($sp, $key, "=", $args->{node}{$key});
    } elsif ($attr->{complete}) {
        if ($attr->{no_value}) {
            $str .= "$key";
        } else {
            $str .= join($sp, "$key", "=", $value);
        }
    } else {
        croak "incomplete option " . join("/", @$path);
    }
    $str .= eol_comment($comment, length($str) + 2);
}

sub eol_comment {
    my ( $comment, $pad ) = @_;
    my $s = "";
    if ( $comment ) {
        my $i = 0;
        for ( split /\n/, $comment ) {
            if ( $i ) {
                $s .= (" ")x$pad;
            } else {
                $s .= "  ";
            }
            $s .= "# $_\n";
            $i++;
        }
    } else {
        $s .= "\n";
    }
    return $s;
}

=item C<populate_template>

 the default template formater

=cut

sub populate_template {
    my ($path, $key, $value, $comment, $attr, $args) = @_;

    if ($attr->{type} eq "option") {
        $args->{cnf} .= option_line(@_);
    } else {
        # non-default comment
        $comment = $args->{comment}{$key} if $args->{comment}{$key};
        #multi-line comment
        $comment =~ s/^/# /mg if $comment;

        if ( $attr->{type} eq "pragma" ) {
            # comment before line
            $args->{cnf} .= "$comment\n" if $comment;
            $args->{cnf} .= "$key $value\n";
        } elsif ( $attr->{type} eq "group" ) {
            # quick hack prepending empty line
            $args->{cnf} .= "\n" if $key eq "mysqld";

            # comment after line
            $args->{cnf} .= "[$key]\n";
            $args->{cnf} .= "$comment\n" if $comment;
        } else {
            # logical groupings
            if ($attr->{type} eq "supergroup") {
                $args->{cnf} .= "\n\n";
            } elsif ($attr->{type} eq 'subgroup') {
                $args->{cnf} .= "\n";
            }
            # comment after spacing lines
            $args->{cnf} .= "$comment\n" if $comment;
        }
    }
}

sub walk_template_ex {
    my ($path, $r, $cb, $args) = @_;
    for (my $i = 0; $i < @$r; $i += 2) {
        my $key = $r->[$i];
        my $value = $r->[$i+1];
        croak "syntax error at $key, expect array reference" unless defined $value && ref($value)eq "ARRAY";
        # explicit condition must meet
        my $cap_ok = ! defined $value->[CONDITION] || $args->{cap}{$value->[CONDITION]};
        # leaves
        if (ref($value->[DEFAULT_SLOT]) eq '') {
            if ($cap_ok) {
                my %attr = (complete => 1, type => 'option');
                # pure abstract
                unless (defined $value->[DEFAULT_SLOT]) {
                    $attr{complete} = 0;
                } elsif ($value->[DEFAULT_SLOT] eq '') {
                    #complete option w/o value
                    $attr{no_value} = 1;
                } else {
                    # complete option w/ value
                }

                if ($key eq '!include') {
                    $attr{type} = 'pragma';
                }

                push @$path, $key;
                $cb && $cb->($path, $key, $value->[DEFAULT_SLOT], $value->[COMMENT], \%attr, $args);
                pop @$path;
            }
        } elsif (ref($value->[DEFAULT_SLOT]) eq "ARRAY") {
            if ($cap_ok) {
               my %type = (
                   g => 'global',
                   s => 'supergroup',
                   r => 'subgroup',
               );

               my %attr = (type => 'group');
               # logical ones like _x_xxx, normal ones are my.cnf [group]
               if ($key =~ /^_(\w)_/) {
                   $attr{type} = $type{$1};
               }
               #recurse deeper level
               push @$path, $key;
               $cb && $cb->($path, $key, $value->[DEFAULT_SLOT], $value->[COMMENT], \%attr, $args);
               walk_template_ex($path, $value->[DEFAULT_SLOT], $cb, $args);
               pop @$path;
            }
        } else {
            croak "syntax error at default slot of $key";
        }
    }
}

BEGIN {
    @node_template = (
        # global context
        _g_include => [
                ['!include' => ['.my.cnf', 'password file, read only by owner'] ],
            ],
        _g_inline => [
            [
            # supergroups
                _s_clients => [
                    [ 
                        mysql => [
                            [ 'prompt' => [q{'mysql \u@[\h:\p \d] > '}],
                            'default-character-set' => [ 'utf8' ], ], ],
                        mysqladmin => [
                            [ 'default-character-set' => [ 'utf8' ], ], ],
                        mysqlcheck => [
                            [ 'default-character-set' => [ 'utf8' ], ], ],
                        mysqldump => [
                            [ 'default-character-set' => [ 'utf8' ], ], ],
                        mysqlimport => [
                            [ 'default-character-set' => [ 'utf8' ], ], ],
                        mysqlshow => [
                            [ 'default-character-set' => [ 'utf8' ], ], ],
                        client => [
                            [
                                'port' => [ ],
                                'socket' => [ ],
                            ], ],
                     ], 'only certain clients support default-character-set' ],
                  
                 _s_server => [
                     [
                         mysqld_safe => [
                             [
                                 _r_mysqld_safe_settings => [
                                     [
                                         syslog => [ '' ],
                                         'syslog-tag' => [ ],
                                     ],
                                 ],
                                 _r_mysqld_safe_numa_settings => [
                                     [
                                         numa_interleave => [ 1, 'numa setting', 'Percona56' ],
                                         innodb_buffer_pool_populate => [ 1, 'use with numa', 'Percona56'],
                                         flush_caches => [ 1, 'use with buffer pool populate', 'Percona56'],
                                     ], 'numa support'],
                             ],
                         ],
                         mysqld => [
                             [
                                 # subgroups, holding related options
                                 _r_node_specific_settings => [
                                     [
                                         'server-id' => [ ], # port + (hostid << 16)
                                     ], 'node specific settings'],
                                 _r_chain_specific_settings => [
                                     [
                                         'port'      => [ ],
                                         'datadir'   => [ ],
                                         'pid-file'  => [ ],
                                         'socket'    => [ ],
                                     ], 'chain specific settings'],
                                 _r_common_innodb_setting => [
                                     [
                                         innodb_buffer_pool_size => [
                                             '12228M',
                                             'x 1.2 + 2GB for OS = 16.4GB node w/o MyISAM',
                                             'node16',],
                                         innodb_buffer_pool_size => [
                                             '25600M',
                                             'x 1.2 + 2GB for OS = 32GB node w/o MyISAM',
                                             'node32',],
                                         innodb_buffer_pool_size => [
                                             '39253M',
                                             'x 1.2 + 2GB for OS = 48GB node w/o MyISAM',
                                             'node48',],
                                         innodb_buffer_pool_size => [
                                             '52906M',
                                             'x 1.2 + 2GB for OS = 64GB node w/o MyISAM',
                                             'node64',],
                                         innodb_log_file_size => [ "256M", 'suitable for most environments' ],
                                         innodb_log_buffer_size => [ '16M', 'no bigger than max_allowed_packet' ],
                                         innodb_flush_log_at_trx_commit => [ 2 ],
                                         innodb_flush_method => [ 'O_DIRECT' ],
                                         innodb_file_per_table => [ 1 ],
                                         innodb_stats_on_metadata => [ 0, 'disable innodb statistics when statistics sql was running' ],
                                         # when innodb is configured, it is default
                                         'default-storage-engine' => [ 'innodb' ],
                                     ], "common InnoDB/XtraDB settings", 'innodb'],
                                 _r_innodb_plugin_settings => [
                                     [
                                         'ignore-builtin-innodb' => [ '', ],
                                         'plugin-load' => [ 
                                             'innodb=ha_innodb_plugin.so;'
                                             . 'innodb_trx=ha_innodb_plugin.so;'
                                             . 'innodb_locks=ha_innodb_plugin.so;'
                                             . 'innodb_cmp=ha_innodb_plugin.so;'
                                             . 'innodb_cmp_reset=ha_innodb_plugin.so;'
                                             . 'innodb_cmpmem=ha_innodb_plugin.so;'
                                             . 'innodb_cmpmem_reset=ha_innodb_plugin.so' ],
                                     ], 'enable InnoDB plugin', 'innodb_plugin' ],
                                 _r_percona_gtid_settings => [
                                     [
                                         gtid_mode => [ 'on', '', 'Percona56' ],
                                         'enforce-gtid-consistency' => [ '', 'use with gtid', 'Percona56' ],
                                     ], 'enable gtid mode'],
				_r_percona_extra_port => [
				     [
				 	 extra_port => [4301, 'additinal port', 'Percona56'],
					 extra_max_connections => [2, 'additinal connections', 'Percona56'],
			  	     ], 'additinal port info'],
                                 _r_percona_enhancements => [
                                     [
                                         'eq_range_index_dive_limit' => [ 5, 'performace for range list', 'Percona56'],
                                         'query_cache_strip_comments' => [ 1, 'ignore comments in query cache', 'Percona56' ],
                                         innodb_corrupt_table_action => [ 'warn', '5.5.10-20.1 introduced', 'Percona56' ],
                                         innodb_recovery_update_relay_log => [ 1, '5.5.10-20.1 introduced', 'Percona55' ],
                                         innodb_overwrite_relay_log_info => [ 1, '5.5.10-20.1 renamed', 'Percona51' ],
                                         innodb_lazy_drop_table => [ 1, '5.6 deprecated', 'Percona51' ],
                                         innodb_lazy_drop_table => [ 1, '5.6 deprecated', 'Percona55' ],
                                         query_cache_type => [
                                             0,
                                             'disable use of the query cache altogether',
                                             'disable_query_cache', ],
                                         innodb_corrupt_table_action => [ 'warn', '5.5.10-20.1 introduced', 'Percona55' ],
                                         innodb_pass_corrupt_table => [ 1, '5.5.10-20.1 renamed', 'Percona51' ],
                                         log_slow_verbosity => [ 'full' ],
                                         userstat_running => [ 1, '5.5.10-20.1 renamed', 'Percona51'],
                                         userstat => [ 1, '5.5.10-20.1 introduced', 'Percona55', 'Percona56'],
										 userstat => [ 1, '5.5.10-20.1 introduced', 'Percona56'],
                                     ], "Percona Server enhancements\n" . ' http://www.percona.com/doc/percona-server', 'xtradb'],
                                 _r_common_business_settings => [
                                     [
                                         back_log => [ 500 ],
                                         max_connections => [ 3000, 'should be easy job in a big server' ],
                                         max_connect_errors => [ 100000 ],
                                         thread_cache_size => [ 64 ],
                                         table_open_cache => [ 1024, 'table_cache is deprecated in 5.1.3' ],
                                         sort_buffer_size => [ '2M' ],
                                         read_buffer_size => [ '2M' ],
                                         join_buffer_size => [ '2M' ],
                                         read_rnd_buffer_size => [ '4M' ],
                                         myisam_sort_buffer_size => [ '128M', 'myisam sort buffer size', 'myisam' ],
                                         key_buffer_size => [
                                             '1G',
                                             'du -shc report 3G as max except click',
                                             'myisam' ], ], 'common business settings for 16GB node' ],
                                 _r_common_mysqld_setttings => [
                                     [
                                         read_only => [ 1, "start read only, turn it off on master " 
                                                           . " afterwards by \n"
                                                           . " 'SET GLOBAL read_only = 0' " ],
                                         expire_logs_days => [ 7, 'not MHA node ', 'auto_expire_relay_log' ],
                                         max_allowed_packet => [ '16M', 'same to master' ],
                                         user => [ 'mysql' ],
                                         'skip-external-locking' => [ '', 'a.k.a skip-locking' ],
                                         'skip-name-resolve' => [''],
                                         'character-set-server' => [ 'utf8', 'default-character-set is deprecated in 5.0' ],
                                         'collation-server' => [ 'utf8_general_ci' ],
                                         'concurrent_insert' => [ 2, 'allows concurrent for MyISAM with holes', 'myisam' ],
                                         tmpdir => [ '/dev/shm' ],
                                         log_output => [ 'FILE' ],
                                         general_log => [ 'OFF' ],
                                         slow_query_log => [ 1, 'ON is not recognized in 5.1.46' ],
                                         long_query_time => [ 1, 'in seconds, determine slow query' ],
                                         general_log_file => [ 'query.log', 'log is deprecated as of 5.1.29' ],
                                         slow_query_log_file => [ 'slow-query.log', "log_slow_queries and log_queries_not_using_index are deprecated as of 5.1.29" ],
                                         slave_skip_errors => [ 1062, 'skip primary duplicate error'],
                                         'log-bin' => [ 'mysql-bin.log' ],
                                         'sync_binlog' => [ 1, 'BBU-backed RAID or flash', 'bbu_raid_or_flash' ],
                                         'relay-log' => [ 'relay-bin.log', 'auto purge by default, see relay-log-purge' ],
                                         'relay-log-purge' => [ 0, 'MHA node', 'mha_node' ],
                                         'log-slave-updates' => [ '' ],
                                         'replicate-same-server-id' => [ 0 ],
                                         'binlog-ignore-db' => [ 'mysql' ],
                                         'binlog-ignore-db' => [ 'test' ],
                                         'binlog-ignore-db' => [ 'information_schema' ],
                                         'binlog-ignore-db' => [ 'performance_schema' ],
                                         'replicate-ignore-db' => [ 'mysql' ],
                                         'replicate-ignore-db' => [ 'test' ],
                                         'replicate-ignore-db' => [ 'information_schema' ],
                                         'replicate-ignore-db' => [ 'performance_schema' ],
                                     ], 'common mysqld setting' ],
                             ],
                         ],  # end of mysqld
                     ], 'on instance per my.node.cnf' ], # end of server supergroup
        ],
    ],
  );
}

1; # return true
