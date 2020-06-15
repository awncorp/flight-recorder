package FlightRecorder;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Data::Object::Role::Pluggable';
with 'Data::Object::Role::Throwable';

# VERSION

# ATTRIBUTES

has 'auto' => (
  is => 'ro',
  isa => 'Maybe[FileHandle]',
  def => sub{\*STDOUT},
);

has 'head' => (
  is => 'ro',
  isa => 'Str',
  opt => 1,
);

has 'item' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1,
);

has 'refs' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1,
  new => 1
);

fun new_refs($self) {
  {}
}

has 'logs' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1,
  new => 1
);

fun new_logs($self) {
  []
}

has level => (
  is => 'rw',
  isa => 'Enum[qw(debug info warn error fatal)]',
  def => 'debug'
);

has 'format' => (
  is => 'rw',
  isa => 'Str',
  opt => 1,
  def => '{head_timestamp} [{head}] @{head_level} {head_message}'
);

has 'zeros' => (
  is => 'ro',
  isa => 'Int',
  opt => 1,
  def => 4
);

# METHODS

method begin(Str $name) {
  $self->context($name);
  $self->message('debug', join(' ', $self->name, 'began'), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method branch(Str $name) {
  my $class = ref $self;
  my $data = $self->serialize;

  $self = $class->new($data);

  $self->context($name);
  $self->message('debug', join(' ', $self->name, 'began'), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method count(Maybe[Str] $level) {
  return int scalar grep {$level ? $$_{level} eq "$level" : 1} @{$self->{logs}};
}

method context(Str $name) {
  my $head = $self->next_refs;

  $self->refs->{$head} = $name;
  $self->{head} = $head;

  return $self;
}

method data(HashRef[Str] $data) {
  my $item = $self->item;

  push @{$item->{data}}, $data;

  return $self;
}

method debug(Str @messages) {
  $self->message('debug', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method end() {
  $self->message('debug', join(' ', $self->name, 'ended'), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method error(Str @messages) {
  $self->message('error', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method fatal(Str @messages) {
  $self->message('fatal', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method head_file() {
  my $item = $self->item;

  return $item->{file};
}

method head_line() {
  my $item = $self->item;

  return $item->{line};
}

method head_name() {
  my $item = $self->item;

  return $item->{name};
}

method head_context() {
  my $item = $self->item;

  return $item->{context};
}

method head_process() {
  my $item = $self->item;

  return $item->{process};
}

method head_package() {
  my $item = $self->item;

  return $item->{package};
}

method head_version() {
  my $item = $self->item;

  return $item->{version};
}

method head_subroutine() {
  my $item = $self->item;

  return $item->{subroutine};
}

method head_timestamp() {
  my $item = $self->item;
  my $time = $item->{timestamp};

  return scalar(localtime($time));
}

method head_message() {
  my $item = $self->item;

  return $item->{message};
}

method head_level() {
  my $item = $self->item;

  return $item->{level};
}

method info(Str @messages) {
  $self->message('info', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method initialize(Tuple[Int, Int] $frames) {
  my $index = ($$frames[0] == 0 && $$frames[1] == 1) ? [2,3] : [3,4];

  $self->context('main');
  $self->message('debug', join(' ', $self->name, 'began'), $index);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method levels() {
  my @levels = qw(debug info warn error fatal);
  my %levels = map +($levels[$_], $_), 0..$#levels;

  return {%levels};
}

method loggable(Str $target_level) {
  my $levels = $self->levels;

  my $loggable_level = $self->level;

  return int($$levels{$target_level} >= $$levels{$loggable_level});
}

method logline() {
  my $item = $self->item;
  my $format = $self->format;
  my @tokens = $format =~ m/\{(\w+)\}/g;

  $format =~ s/\{$_\}/$self->token($_)/ge for @tokens;

  return $format;
}

method message(Str $level, Str $message, Tuple[Int, Int] $frames = [0,1]) {
  my $process = $$;
  my $caller = [caller($$frames[0])];
  my $file = $caller->[1];
  my $line = $caller->[2];
  my $context = $self->head || $self->initialize($frames)->head;
  my $package = $caller->[0];
  my $subroutine = (caller($$frames[1]))[3];
  my $timestamp = time;
  my $version = $caller->[0] ? $caller->[0]->VERSION : undef;
  my $name = $self->name;

  my $entry = {
    context => $context,
    data => [],
    file => $file,
    level => $level,
    line => $line,
    message => $message,
    name => $name,
    package => $package,
    process => $process,
    subroutine => $subroutine,
    timestamp => $timestamp,
    version => $version
  };

  push @{$self->{logs}}, $entry;

  $self->{item} = $entry;

  return $self;
}

method name() {
  my $head = $self->head;

  return $self->refs->{$head};
}

method next_name() {

  return $self->next_from_logs($self->logs);
}

method next_refs() {

  return $self->next_from_hash($self->refs);
}

method next_from_hash(HashRef $hash) {
  my $zeros = $self->zeros;

  return sprintf "%0${zeros}d", (keys %$hash) + 1;
}

method next_from_logs(ArrayRef $logs) {
  my $zeros = $self->zeros;

  return sprintf "%0${zeros}d", (@$logs) + 1;
}

method output(FileHandle $handle = \*STDOUT) {
  my $logline = $self->logline;

  print $handle $logline, "\n" if $self->loggable($self->head_level);

  return $logline;
}

method report(Str $name, Str $level = $self->level) {
  my %args = (level => $level, flight_recorder => $self);

  return $self->plugin("report_$name" => (%args));
}

method reset() {
  delete $self->{head};
  delete $self->{item};
  delete $self->{refs};
  delete $self->{logs};

  return $self;
}

method serialize() {
  my $data = {};

  $data->{head} = $self->head;
  $data->{level} = $self->level;
  $data->{logs} = $self->logs;
  $data->{refs} = $self->refs;
  $data->{zeros} = $self->zeros;

  return $data;
}

method simple(Str $level = $self->level) {

  return $self->report('simple', $level);
}

method succinct(Str $level = $self->level) {

  return $self->report('succinct', $level);
}

method switch(Str $name) {
  my $context = {reverse %{$self->refs}}->{$name};
  my $selected = [grep {$$_{context} eq $context} @{$self->logs}];

  if (@$selected) {
    $self->{head} = $context;
    $self->{item} = $selected->[-1];
  }

  return $self;
}

method token(Str $name) {
  my $item = $self->item;

  return $self->$name if $self->can($name);

  return "{$name}";
}

method verbose(Str $level = $self->level) {

  return $self->report('verbose', $level);
}

method warn(Str @messages) {
  $self->message('warn', join(' ', @messages), [1,2]);

  return $self;
}

1;
