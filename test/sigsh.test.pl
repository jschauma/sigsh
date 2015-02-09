# Copyright (c) 2010,2011 Yahoo! Inc.
#
# A test to verify that the shell implementation works as expected.

use strict;
use warnings;

use Test::Command;
use Test::More tests => 10;

system("openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout mykey.pem -out mycert.pem -batch >/dev/null 2>&1");

my $signed_input = "openssl smime -sign -nodetach -signer mycert.pem -inkey mykey.pem -outform pem";

my $uname = `uname`;
chomp($uname);
my $perl = `which perl`;
chomp($perl);

my $sigsh = "sh ../src/sigsh.sh -f ./mycert.pem";
my $cmd = "echo uname | $signed_input | $sigsh";
my $test = Test::Command->new( cmd => $cmd);
$test->stdout_like(qr/^$uname$/, "uname was invoked after verification");

$cmd = "echo uname | $signed_input | $sigsh -x";
$test = Test::Command->new( cmd => $cmd);
$test->stderr_like(qr/^\+ openssl smime/, "tracing of openssl commands works");
$test->stderr_like(qr/Verification successful/, "tracing of openssl commands works");
$test->stderr_like(qr/\+ uname/, "tracing of commands works");


$cmd = "echo uname | $sigsh";
$test = Test::Command->new( cmd => $cmd);
$test->stderr_like(qr/^Unable to verify given input.$/, "uname was not invoked if not signed");
$test->exit_is_num(127,		"exit code for verification failure is 127");

$cmd = "echo uname | $sigsh -x";
$test = Test::Command->new( cmd => $cmd);
$test->stderr_like(qr/Error reading S\/MIME message/, "openssl error messages are traced");

$cmd = "( echo \"#!/bin/sh\"; echo; echo uname; echo \"exit 42\"; ) | $signed_input | $sigsh";
$test = Test::Command->new( cmd => $cmd);
$test->stdout_like(qr/^$uname$/, "multi-line script was executed");
$test->exit_is_num(42,		"exit code is returned");

$cmd = "echo '\$foo = 5; print \"Number \$foo!\\n\"' | $signed_input | $sigsh -p $perl";
$test = Test::Command->new( cmd => $cmd);
$test->stdout_like(qr/^Number 5!$/,  "perl script was executed");

system("rm mycert.pem mykey.pem");
