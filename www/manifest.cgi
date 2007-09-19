#!/usr/bin/perl

$ENV{"QUERY_STRING"} .= "&manifest=1";
do "download.cgi";
