package Albatross::SocialNetwork;

use strict;
use warnings;

use Dancer2;

use Try::Tiny;

any '/**' => sub {
    pass if request->path eq '/';

    if (!session('user') && request->path !~ m{^/login\b}) {
        if (request->path =~ m{^/ping}) { # special '/ping' path: allows front-end to test for a valid login
            status 'forbidden';
        } else {
            status 'unauthorized';
        }
        return encode_json {
            errors => [ { code => 'forbidden', msg => 'You need to log in to access this page', }, ],
        };
    }

    pass;
};

get '/' => sub {
    return encode_json {};
};

1;
