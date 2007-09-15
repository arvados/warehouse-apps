#!/usr/bin/perl

$ENV{"QUERY_STRING"} .= "&manifest=1&noprefix=1";
do "download.cgi";
