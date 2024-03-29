#!/usr/bin/env perl

#####################################################################################
#
# Copyright (c) 2012, Alexander Todorov <atodorov()otb.bg>. See POD section.
#
#####################################################################################

package App::Monupco::OpenShift;
our $VERSION = '0.10';
our $NAME = "monupco-openshift-perl";

use App::Monupco::OpenShift::Parser;
@ISA = qw(App::Monupco::OpenShift::Parser);

use strict;
use warnings;

use JSON;
use LWP::UserAgent;

my $data = {
    'user_id'    => $ENV{'MONUPCO_USER_ID'},
    'app_name'   => $ENV{'OPENSHIFT_GEAR_NAME'},
    'app_uuid'   => $ENV{'OPENSHIFT_GEAR_UUID'},
    'app_type'   => $ENV{'OPENSHIFT_GEAR_TYPE'},
    'app_url'    => "http://$ENV{'OPENSHIFT_GEAR_DNS'}",
    'app_vendor' => 0,   # Red Hat OpenShift
    'pkg_type'   => 400, # Perl / CPAN
    'installed'  => [],
};

my $pod_parsed = "";
my $parser = App::Monupco::OpenShift::Parser->new();
$parser->output_string( \$pod_parsed );
$parser->parse_file("$ENV{'OPENSHIFT_GEAR_DIR'}/perl5lib/lib/perl5/x86_64-linux-thread-multi/perllocal.pod");

my @installed;
foreach my $nv (split(/\n/, $pod_parsed)) {
    my @name_ver = split(/ /, $nv);
    push(@installed, {'n' => $name_ver[0], 'v' => $name_ver[1]});
}


$data->{'installed'} = [ @installed ];

my $json_data = to_json($data); # , { pretty => 1 });

my $ua = new LWP::UserAgent(('agent' => "$NAME/$VERSION"));

# will URL Encode by default
my $response = $ua->post('https://monupco-otb.rhcloud.com/application/register/', { json_data => $json_data});

if (! $response->is_success) {
    die $response->status_line;
}

my $content = from_json($response->decoded_content);
print "Monupco: $content->{'message'}\n";

exit $content->{'exit_code'};


1;
__END__

=head1 NAME

App::Monupco::OpenShift - monupco.com registration agent for OpenShift / Perl applications

=head1 SYNOPSIS

To register your OpenShift Perl application to Monupco do the following:

1) Create a Perl application on OpenShift:

    rhc-create-app -a myapp -t perl-5.10

2) Add a dependency in your deplist.txt file

    cd ./myapp/
    echo "App::Monupco::OpenShift" >> deplist.txt

3) Set your userID in the ./data/MONUPCO_SETTINGS file

    echo "export MONUPCO_USER_ID=YourUserID"  > ./data/MONUPCO_SETTINGS

4) Enable the registration script in .openshift/action_hooks/post_deploy

    source $OPENSHIFT_REPO_DIR/data/MONUPCO_SETTINGS
    export PERL5LIB=$OPENSHIFT_GEAR_DIR/perl5lib/lib/perl5/
    $OPENSHIFT_GEAR_DIR/perl5lib/lib/perl5/App/Monupco/OpenShift.pm

5) Commit your changes

    git add .
    git commit -m "enable monupco registration"

6) Then push your application to OpenShift

    git push

That's it, you can now check your application statistics at
http://monupco.com


=head1 DESCRIPTION

This module compiles a list of locally installed Perl distributions and sends it to
http://monupco.com where you check your application statistic and available updates.

=head1 AUTHOR

Alexander Todorov, E<lt>atodorov()otb.bgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2012, Alexander Todorov <atodorov()otb.bg>

 This module is free software and is published under the same terms as Perl itself.

=cut
