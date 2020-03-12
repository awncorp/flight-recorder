package FlightRecorder::Plugin::ReportVerbose;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

extends 'FlightRecorder::Plugin::Report';

# VERSION

# METHODS

method format() {
  my @template;

  push @template, '{item_timestamp}';
  push @template, '[{item_context}]';
  push @template, '@{item_level}';
  push @template, '[{item_process}]';
  push @template, "BEGIN\n\n{item_report}\n\nEND\n";

  return join ' ', @template;
}

method item_report(HashRef $item) {
  my @info;

  my $file = $self->item_file($item);
  my $line = $self->item_line($item);

  push @info, "In $file at line #$line", "";

  push @info, $self->item_dump({
    context => $self->item_name($item),
    message => $self->item_message($item)
  });

  push @info, $self->item_dump({
    package => $self->item_package($item),
    process => $self->item_process($item),
    subroutine => $self->item_subroutine($item),
    version => $self->item_version($item),
    timestamp => $item->{timestamp}
  });

  for my $include (@{$item->{data}}) {
    push @info, $self->item_dump($include);
  }

  my $report = join "\n", @info;

  chomp $report;

  return $report;
}

1;
