package FlightRecorder::Plugin::ReportSimple;

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

  return '{item_timestamp} [{item_context}] @{item_level} {item_message}';
}

1;