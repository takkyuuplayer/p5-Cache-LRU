package Cache::LRU;
use warnings;
use utf8;

sub new {
    my $class = shift;

    my %args = @_;

    bless {
        max_size => $args{max_size} || 3,
        current_size => 0,
        cache        => {},
        start        => undef,
        end          => undef,
    }, $class;
}

sub max_size {
    my $self = shift;

    $self->{max_size};
}

sub current_size {
    my $self = shift;

    $self->{current_size};
}

sub set {
    my ($self, $key, $value) = @_;

    if (my $current = $self->{cache}{$key}) {
        if($current->{prev} && $current->{next}) {
            $current->{prev}{next} = $current->{next};
            $current->{next}{prev} = $current->{prev};
        }
        $self->{end} = $current->{prev} if not $current->{next} && $current->{prev};
    }
    else {
        $self->{current_size}++;
    }

    $self->{cache}{$key} = {
        prev  => undef,
        next  => undef,
        value => $value,
        key   => $key,
    };

    if ($self->current_size > $self->max_size) {
        $self->remove($self->{end}{key});
    }

    $self->{cache}{$key}{next} = $self->{start}
        if defined($self->{start}) && $self->{start}{key} ne $key;
    $self->{start} = $self->{cache}{$key};
    $self->{end} = $self->{cache}{$key} if not $self->{end};
}

sub get {
    my ($self, $key) = @_;

    my $current = $self->{cache}{$key};

    return if not $current;

    $current->{prev}{next} = $current->{next} if $current->{prev};
    $current->{next}{prev} = $current->{prev} || $current if $current->{next};
    $self->{start} = $current;

    if ($self->{end} && $key eq $self->{end}{key}) {
        $self->{end} = $current->{prev};
    }

    $current->{value};
}

sub remove {
    my ($self, $key) = @_;

    my $current = delete $self->{cache}{$key};

    return if not $current;

    $self->{current_size}--;

    $current->{prev}{next} = $current->{next} if $current->{prev};
    $current->{next}{prev} = $current->{prev} if $current->{next};

    $self->{start} = $current->{next} if not $current->{prev};
    $self->{end}   = $current->{prev} if not $current->{next};
}

1;
