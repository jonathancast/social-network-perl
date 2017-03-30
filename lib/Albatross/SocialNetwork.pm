package Albatross::SocialNetwork;

use strict;
use warnings;

use Dancer2;

use Try::Tiny;

set serializer => 'JSON';

any '/**' => sub {
    pass if request->path eq '/';

    if (!session('user') && request->path !~ m{^/login\b}) {
        if (request->path =~ m{^/ping}) { # special '/ping' path: allows front-end to test for a valid login
            status 'forbidden';
        } else {
            status 'unauthorized';
        }
        return {
            errors => [ { code => 'forbidden', msg => 'You need to log in to access this page', }, ],
        };
    }

    pass;
};

get '/' => sub {
    return {};
};

post '/login' => sub {
    my $login_id = params->{login_id};
    unless ($login_id) {
        status 'forbidden';
        return { errors => [ { code => 'badparams', missing => [ 'login_id', ], msg => 'You must supply a login_id', }, ], };
    }

    my $password = params->{password};
    unless ($password) {
        status 'forbidden';
        return { errors => [ { code => 'badparams', missing => [ 'password', ], msg => 'You must supply a password', }, ], };
    }

    ...
};

1;
