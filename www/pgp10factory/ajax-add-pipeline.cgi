#!/usr/bin/perl

use strict;
use CGI;
use Digest::MD5 'md5_hex';
use POSIX;
do "session.pm";

my $workdir = "./cache";
mkdir $workdir;
chmod 0777, $workdir;
die "$workdir could not be created / is not writeable" unless -d $workdir && -w $workdir;

my $q = new CGI;
session::init($q);
print $q->header (-type => "text/plain",
		  -cookie => [session::togo()]);
my $sessionid = session::id();

my @pipelinespec;
my @pipelinetype = split (":", $q->param ("pipeline"));
my @pipelinespec = ("pipeline=".shift @pipelinetype);
for (my $i=0; $i <= $#pipelinetype; $i+=2)
{
    if (length ($q->param ($pipelinetype[$i])))
    {
	push @pipelinespec, $pipelinetype[$i]."=".$q->param ($pipelinetype[$i]);
    }
}

my $spec = join ("\n", @pipelinespec)."\n";
my $specmd5 = md5_hex ($spec);
my $json = qq{{ "workflow": { "id": "$specmd5", "message": "Pipeline submitted to local queue." } }\n};

if (sysopen F, "$workdir/$specmd5.ispipeline", O_WRONLY|O_CREAT|O_EXCL)
{
    syswrite F, $spec;
}
if (!sysopen F, "$workdir/$specmd5", O_WRONLY|O_CREAT|O_EXCL)
{
    if (sysopen F, "$workdir/$specmd5", O_RDONLY)
    {
	local $/ = undef;
	$json = <F>;
	close F;
    }
}
sysopen F, "./session/$sessionid/$specmd5", O_WRONLY|O_CREAT|O_EXCL;
close F;

print $json;
