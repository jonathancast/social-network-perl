use Moops;

class Albatross::SocialNetwork::Schema::Result::User extends DBIx::Class::EncodedColumn, DBIx::Class::Core {
    use DBIx::Class::Candy -autotable => v1;

    primary_column id => {
        data_type => 'int',
        is_auto_increment => 1,
    };

    unique_column login_id => {
        data_type => 'text',
    };

    column password => {
        data_type => 'text',
        encode_column => 1,
        encode_class  => 'Digest',
        encode_args   => { algorithm => 'SHA-512', format => 'hex', salt_length => 12, },
        encode_check_method => 'check_password',
    };

    method as_hash(@cols) {
        return { map { $_ => $self->$_ } @cols };
    }
}

1;
