use Moops;

class Albatross::SocialNetwork::Schema::Result::User {
    use DBIx::Class::Candy -autotable => v1;

    primary_column id => {
        data_type => 'int',
        is_auto_increment => 1,
    };

    unique_column login_id => {
        data_type => 'text',
    };
}

1;
