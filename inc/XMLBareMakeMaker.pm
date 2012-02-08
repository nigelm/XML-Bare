package inc::XMLBareMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my ($self) = @_;

    return +{
        %{ super() },
        OBJECT => 'Bare.o parser.o',
        XSOPT  => '-nolinenumbers',    # line number defines were causing issues on some platforms

    };
};

__PACKAGE__->meta->make_immutable;
