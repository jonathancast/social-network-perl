package T::TestDB;

use strict;
use warnings;

use File::Path qw/ make_path /;

use Albatross::SocialNetwork::Schema;

sub import {
    $ENV{DANCER_ENVIRONMENT} = 'test';

    make_path('t/db');
    unlink('t/db/test.db');

    Albatross::SocialNetwork::Schema->connect('dbi:SQLite:dbname=t/db/test.db')->deploy();
}

1;
