package Albatross::SocialNetwork;

use strict;
use warnings;

use Dancer2;

use Try::Tiny;

get '/' => sub {
    return encode_json({});
};

1;
