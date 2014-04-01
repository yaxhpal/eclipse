#!/usr/bin/perl

# Copyright 2011 Nucsoft Osslabs (Member Registartion amit.gupta@osslabs.biz)
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;

use CGI;
use C4::Auth;    # checkauth, getborrowernumber.
use C4::Context;
use C4::Koha;
use C4::Output;

my $input = new CGI;
my $op = $input->param('op');
my $refresh = $input->param('was_refreshed');
my $dbh = C4::Context->dbh;

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "opac-onlinemembership.tmpl",
        query           => $input,
        type            => "opac", 
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
        debug           => 1,      
    }
);
$template->param( from_ext => 1,
				was_refreshed => $refresh);
output_html_with_http_headers $input, $cookie, $template->output;



