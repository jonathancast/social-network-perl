package T::TestDB;

use strict;
use warnings;

use Import::Into;

use DBICx::Sugar ();

use File::Path qw/ make_path /;

use Albatross::SocialNetwork::Schema;

sub import {
    $ENV{DANCER_ENVIRONMENT} = 'test';

    make_path('t/db');
    unlink('t/db/test.db');

    my $dsn = 'dbi:SQLite:dbname=t/db/test.db';

    Albatross::SocialNetwork::Schema->connect($dsn)->deploy();

    DBICx::Sugar::config({ default => { dsn => $dsn, schema_class => 'Albatross::SocialNetwork::Schema', } });

    DBICx::Sugar->import::into(scalar caller, qw/ schema /);
}

1;
