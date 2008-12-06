package ObjectDB::Base;
# from Mojo::Base

use strict;
use warnings;

require Carp;

sub new {
    my $class = shift;

    return bless
      exists $_[0] ? exists $_[1] ? {@_} : $_[0] : {},
      ref $class || $class;
}

sub attr {
    my $class = shift;
    my $attrs = shift;

    # Shortcut
    return unless $class && $attrs;

    # Check arguments
    my $args;
    if (exists $_[1]) {
        my %args = (@_);
        $args = \%args;
    }
    else { $args = $_[0] }
    $args ||= {};

    my $chained = delete $args->{chained};
    my $default = delete $args->{default};
    my $weak    = delete $args->{weak};

    undef $args;

    # Check default
    Carp::croak('Default has to be a code reference or constant value')
      if ref $default && ref $default ne 'CODE';

    # Allow symbolic references
    no strict 'refs';

    # Create attributes
    $attrs = ref $attrs eq 'ARRAY' ? $attrs : [$attrs];
    my $ws = '    ';
    for my $attr (@$attrs) {

        Carp::croak("Attribute '$attr' invalid")
          unless $attr =~ /^[a-zA-Z_]\w*$/;

        # Header
        my $code = "sub {\n";

        # Warning gets optimized away
        unless ($ENV{OBJECTDB_BASE_OPTIMIZE}) {

            # Check invocant
            $code .= "${ws}Carp::confess(q[";
            $code
              .= qq/Attribute "$attr" has to be called on an object, not a class/;
            $code .= "])\n  ${ws}unless ref \$_[0];\n";
        }

        # No value
        $code .= "${ws}if (\@_ == 1) {\n";
        unless (defined $default) {

            # Return value
            $code .= "$ws${ws}return \$_[0]->{'$attr'};\n";
        }
        else {

            # Return value
            $code .= "$ws${ws}return \$_[0]->{'$attr'} ";
            $code .= "if exists \$_[0]->{'$attr'};\n";

            # Return default value
            $code .= "$ws${ws}return \$_[0]->{'$attr'} = ";
            $code .=
              ref $default eq 'CODE'
              ? '$default->($_[0])'
              : '$default';
            $code .= ";\n";
        }
        $code .= "$ws}\n";


        # Store argument optimized
        if (!$weak && !$chained) {
            $code .= "${ws}return \$_[0]->{'$attr'} = \$_[1];\n";
        }

        # Store argument the old way
        else {
            $code .= "$ws\$_[0]->{'$attr'} = \$_[1];\n";
        }

        # Weaken
        $code .= "${ws}Scalar::Util::weaken(\$_[0]->{'$attr'});\n" if $weak;

        # Return value or instance for chained/weak
        if ($chained || $weak) {
            $code .= "${ws}return ";
            $code .= $chained ? '$_[0]' : "\$_[0]->{'$attr'}";
            $code .= ";\n";
        }

        # Footer
        $code .= '};';

        # We compile custom attribute code for speed
        *{"${class}::$attr"} = eval $code;

        # This should never happen (hopefully)
        Carp::croak("Mojo::Base compiler error: \n$code\n$@\n") if $@;

        # Debug mode
        if ($ENV{OBJECTDB_BASE_DEBUG}) {
            warn "\nATTRIBUTE: $class->$attr\n";
            warn "$code\n\n";
        }
    }
}

1;
