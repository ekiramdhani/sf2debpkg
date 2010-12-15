package Liip::Debian::Helper;

use strict;
use warnings;

use File::Slurp;

use constant TEMPLATE_DIR => 'packaging/debian_templates/';

sub new {
    my $class = shift;
    my $globalconfig = shift;
    my $self = {
        globalconfig => $globalconfig
    };
    bless $self, $class;
    return $self;
}

# Template specified input file into a specified file, searching for strings which
# 1 appear as keys in %config, and
# 2 are surrounded by the maketime templating marker "_-_",
# then replacing them with the corrosponding value in %config
# eg a file containing "Wanted to say _-_greeting_-_ from _-_packagename_-_"
# might be copied into coderoot/debian as: "Wanted to say hello world from moodle-site-hogwarts"
# If appname is specified, it is appended to the packagename, sitename, wwwroot and wwwrootns variables
sub template_file {
    my ($self, $infile, $outfile, $subst, $appname) = @_;
    my $data = $self->template_file_string($infile, $subst, $appname);
    write_file($outfile, $data);
}

# helper for template_file - returns the result as a string
# rather than writing it out to a file.
# for the arguments, see template_file comments.
sub template_file_string {
    my ($self, $infile, $subst, $appname) = @_;
    my $data = read_file(TEMPLATE_DIR . $infile);

    return $self->template_string_string($data, $subst, $appname);
}

# helper function that actually does the templating
sub template_string_string {
    my ($self, $data, $subst, $appname) = @_;
    my %mergedsubst = %{$self->{globalconfig}};

    @mergedsubst{keys %$subst} = values %$subst;

    my $key;
    if ($appname) {
        $mergedsubst{APPNAME} = $appname;
    }
    foreach $key ( keys %mergedsubst ) {
        my $value = $mergedsubst{$key};
        if ($appname && grep(/$key/, qw(PACKAGENAME SITENAME WWWROOT WWWROOTNS))) {
            $value .= '-' . $appname;
        }
        $value = '' unless defined $value;
        $data =~ s/_-_${key}_-_/$value/gxms;
    }
    return $data;
}

# helper function to return the safe wwwroot for templating
# pass a boolean in the third parameter to control whether this is a debian relative path or not
sub safe_wwwroot {
    my ($self, $appname, $absolute) = @_;
    my $safewwwroot = $self->{globalconfig}->{WWWROOT} . '-' . $appname;
    $absolute || $safewwwroot =~ s/^\///;        # remove initial /
    $safewwwroot =~ s/(.*)([^\/])$/$1$2\//;  # add trailing /
    return $safewwwroot;

}
1
