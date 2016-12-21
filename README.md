[![Build Status](https://travis-ci.org/Perl-VMware/perl-VMware-vCloud.svg?branch=master)](https://travis-ci.org/Perl-VMware/perl-VMware-vCloud)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/VMware-vCloud.png)](http://cpants.charsbar.org/dist/overview/VMware-vCloud)
[![GitHub issues](https://img.shields.io/github/issues/Perl-VMware/perl-VMware-vCloud.svg)](https://github.com/Perl-VMware/perl-VMware-vCloud/issues)
[![GitHub tag](https://img.shields.io/github/tag/Perl-VMware/perl-VMware-vCloud.svg)]()
[![Cpan license](https://img.shields.io/cpan/l/VMware-vCloud.svg)](https://metacpan.org/release/VMware-vCloud)
[![Cpan version](https://img.shields.io/cpan/v/VMware-vCloud.svg)](https://metacpan.org/release/VMware-vCloud)

# NAME

VMware::vCloud - VMware vCloud Director

# VERSION

version 2.405

# SYNOPSIS

    my $vcd = new VMware::vCloud ( $hostname, $username, $password, $orgname, { debug => 1 } );
    my %vapps = $vcd->list_vapps();

    my $vappid = $vapps{'My Personal vApp'};

    my $vapp = $vcd->get_vapp($vappid);
    my $ret = $vapp->power_on();

# DESCRIPTION

This module provides a Perl interface to VMware's vCloud Director.

It's intention is to provide a high-level perl-style interface to vCloud
Director actions.

If you are looking for a direct and low-level access to the vCloud API, you may
want to look at VMware::API::vCloud, which is packaged and used by this module.

# BROKEN COMPATIBILITY

Versions of this module up to and including version `2.404` used the
[XML::Simple](https://metacpan.org/pod/XML::Simple) default XML to hash folding mechanism which would take the first
one of `name`, `key` and `id` to use at the hash key attribute.  This caused
problems where multiple items with the same name could occur.  This version
only uses the `id` attribute to fold into hashes.  This means that some code
will need adjusting to deal with the changed hash folding.

# EXAMPLE SCRIPTS

Included in the distribution of this module are several example scripts.
Hopefully they provide an illustrative example of the use of vCloud Director.
All scripts have their own POD and accept command line parameters in a similar
way to the VIPERL SDK utilities and vghetto scripts.

        login.pl - An example script that demonstrates logging in to the server.
        org_get.pl - Selects a random organization and prints a Data::Dumper dump of it's information.
        list-vapps.pl - Prints a list of all VMs the user has access to.

# MODULE METHODS

## new($host,$user,$pass,$org,$conf)

This method instances the VMware::vCloud object and verifies the user can log
onto the server.

$host, $user, and $pass are required. They should contain the login information
for the vCloud server.

$org and $conf are optional.

$org is the vCloud Organization to connect to. If $org is not given, the
default of 'System' is used.

$conf is an optional hasref containing tuneable parameters:

- debug - set to a true value to turn on STDERR debugging statements.

## debug(1|0)

This turns debugging on and off programatically. An argument of '1' for
debugging, '0' for no debugging.

## login()

This method is deprecated and will be removed in later releases.

This method roughly emulates the default login action of the API: It returns
information on which organizations are accessible to the user.

It is a synonym for list\_orgs() and all details on return values should be take
from that method's documentation.

## purge()

This method clears the in-module caching of API responses.

This module caches many API calls to reduce response times and load on the
server. This cache is automatically cleared when a method that changes the
status of the VCD server is called. However, there may be times when you have a
lon running process, or wish to manually clear the cache yourself.

# VAPP METHODS

## create\_vapp\_from\_template($name,$vdcid,$tmplid,$netid)

Given a name, VDC, template and network, instantiate the template with the
given settings and other defaults.

Details of the create task will be returned.

## create\_vapp\_from\_sources(...)

Create a vApp from varied sources

Details of the create task will be returned.

## delete\_vapp($vapp\_href)

Given the org HREF, call a delete on it.

## get\_vapp($vappid)

Given an vApp id, it returns a vApp object for that vApp.

See the documentation on VMware::vCloud::vApp for full details on this object
type.

## list\_vapps()

This method returns a hash or hashref of Template names and IDs the user has
access too.

# TEMPLATE METHODS

## get\_template($templateid)

Given an organization id, it returns a hash of data for that organization.

## list\_templates()

This method returns a hash or hashref of Template names and IDs the user has
access too.

# CATALOG METHODS

## create\_catalog($org\_href,$conf)

This method creates a new, empty catalog in the given organization.

$conf is a hashref that can contain:

- name
- description
- is\_published

Org HREF example: http://example.vcd.server/api/admin/org/{id}

## delete\_catalog($catalog\_href)

Given the org HREF, call a delete on it.

# ORG METHODS

## create\_org(\\%conf)

## delete\_org($org\_href)

Given the org HREF, call a delete on it.

## delete\_org\_network($org\_network\_href)

Given the org network HREF, call a delete on it.

## disable\_org($org\_href)

Given a Org href, call the disable action on it.

## enable\_org($org\_href)

Given a Org href, call the enable action on it.

## get\_org($org\_href)

Given an organization id, it returns a hash or hashref of data for that
organization. Returned data:

    name - Name of the organization
    description - Description field of the organization
    href - anchor HREF for the organization in the API
    id - UUID identified in the href.

    contains - A hashref of contained objects

    catalogs = references to the catalogs within the org
    vdcs - references to the org VDCs within the org

    raw - The raw returned XML structure for the organization from the API

## list\_orgs()

This method returns a hash or hashref of Organization names and IDs.

# ORG VDC METHODS

## create\_vdc($org\_url,$conf)

## delete\_vdc($vdc\_href);

Given the org VDC HREF, call a delete on it.

## disable\_vdc($vdc\_href)

Given a VDC href, call the disable action on it.

## enable\_vdc($vdc\_href)

Given a VDC href, call the enable action on it.

## get\_vdc($vdc\_href)

Given an VDC href, it returns a hash of data for that vDC.

## list\_vdcs() | list\_vdcs($orgid)

This method returns a hash or hashref of VDC names and IDs the user has access
too.

The optional argument of an $orgname will limit the returned list of VDCs in
that Organization.

# PROVIDER VDC METHODS

## get\_pvdc($pvdc\_href)

Returns a hashref of the information on the PVDC

## list\_pvdcs()

Returns a hashref of the information on available PVDCs

# NETWORK METHODS

## create\_org\_network

Create an org network

The conf hash reference can contain:

- name
- desc
- gateway
- netmask
- dns1
- dns2
- dnssuffix
- is\_enabled
- is\_shared
- start\_ip
- end\_ip

## list\_networks() | list\_networks($vdcid)

This method returns a hash or hashref of network names and IDs.

Given an optional VDCid it will return only the networks available in that VDC.

# TASKS

### get\_task($href)

Returns a hash or hashref of the given task.

Contents include: (but aren't limited to)

- href
- operation
- expiryTime
- startTime
- Progress
- operationName
- operation
- status

### progress\_of\_task($task\_href)

    my ($percent,$status) = $vcd->progress_of_task($task_href)

Returns the approximate percentage of completion of the task as an integer
between 1 and 101.

The text status of the task is returned as well:

- queued - The task has been queued for execution.
- preRunning - The task is awaiting preprocessing or administrative action.
- running - The task is running.
- success - The task completed with a status of success.
- error - The task encountered an error while running.
- cancelled - The task was canceled by the owner or an administrator.
- aborted - The task was aborted by an administrative action.

### wait\_on\_task($href)

Given a task href, this method will query the task every second, and only
return once the task is completed.

Specifically, this method will block and continue to query the task while it
has any of the following statuses:

- queued - The task has been queued for execution.
- preRunning - The task is awaiting preprocessing or administrative action.
- running - The task is running.

Any of the following statuses will cause this method to return:

- success - The task completed with a status of success.
- error - The task encountered an error while running.
- cancelled - The task was canceled by the owner or an administrator.
- aborted - The task was aborted by an administrative action.

The return value will be and array or arrayref composed of two elements:

- The status code returned by the server
- A hashref comprising the most recently retrived for of the task object. IE:
the same output as get\_task()

# ADMINISTRATIVE METHODS

### admin\_urls()

Returns the list of administrative action URLs available to the user.

### create\_external\_network($name,$gateway,$netmask,$dns1,$dns2,$suffix,$vimref,$moref,$objtype)

### extensions()

Returns the data structure for the admin extensions available.

## list\_datastores()

Requires using a sysadmin account and attaching to the System org.

Returns a hash(ref) of datastore information.

### list\_external\_networks()

Returns a hash or hasref of all available external networks.

### list\_portgroups()

Returns a hash or hashref of available portgroups on the first associated
vcenter server.

### vimserver()

Returns a reference to the first associated vcenter server.

### webclienturl($type,$moref)

Give the vimserver type and managed object reference, this method returns the
URL for viewing the object via the vSphere Web client. This is handy for
finding further details on objects within vSphere.

# NOTES

## ID VERSUS HREF

Tl;DR - Use HREFs and not IDs.

Internally, objects are identified in the vCloud Director API via either an
UUID or a HREF that references that object.

According to the API documentation, (as of 5.1) UUIDs are not guaranteed to
always be consistent between connections, but HREFs are considered permanent.

Consequently, it is considered a best practice to use HREFs as the unique
identifier of an object. This module implements this best practice.

# DEPENDENCIES

    Cache::Bounded
    VMware::API::vCloud

# AUTHORS

- Phillip Pollard <bennie@cpan.org>
- Nigel Metheringham <nigelm@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Phillip Pollard <bennie@cpan.org>.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc VMware::vCloud

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [http://metacpan.org/release/VMware-vCloud](http://metacpan.org/release/VMware-vCloud)

- Search CPAN

    The default CPAN search engine, useful to view POD in HTML format.

    [http://search.cpan.org/dist/VMware-vCloud](http://search.cpan.org/dist/VMware-vCloud)

- RT: CPAN's Bug Tracker

    The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

    [https://rt.cpan.org/Public/Dist/Display.html?Name=VMware-vCloud](https://rt.cpan.org/Public/Dist/Display.html?Name=VMware-vCloud)

- AnnoCPAN

    The AnnoCPAN is a website that allows community annotations of Perl module documentation.

    [http://annocpan.org/dist/VMware-vCloud](http://annocpan.org/dist/VMware-vCloud)

- CPAN Ratings

    The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

    [http://cpanratings.perl.org/d/VMware-vCloud](http://cpanratings.perl.org/d/VMware-vCloud)

- CPAN Forum

    The CPAN Forum is a web forum for discussing Perl modules.

    [http://cpanforum.com/dist/VMware-vCloud](http://cpanforum.com/dist/VMware-vCloud)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/VMware-vCloud](http://cpants.cpanauthors.org/dist/VMware-vCloud)

- CPAN Testers

    The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/V/VMware-vCloud](http://www.cpantesters.org/distro/V/VMware-vCloud)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=VMware-vCloud](http://matrix.cpantesters.org/?dist=VMware-vCloud)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=VMware::vCloud](http://deps.cpantesters.org/?module=VMware::vCloud)

## Bugs / Feature Requests

Please report any bugs or feature requests by email to `bug-vmware-vcloud at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/Public/Bug/Report.html?Queue=VMware-vCloud](https://rt.cpan.org/Public/Bug/Report.html?Queue=VMware-vCloud). You will be automatically notified of any
progress on the request by the system.

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/Perl-VMware/perl-VMware-vCloud](https://github.com/Perl-VMware/perl-VMware-vCloud)

    git clone https://github.com/Perl-VMware/perl-VMware-vCloud.git

# CONTRIBUTORS

- Michal Ingeli <mi@v3.sk>
- Paulo E. Castro <pauloedgarcastro@gmail.com>
- Dave Gress, <dgress@vmware.com> - Handling org admin issues and metadata
- Stuart Johnston, <sjohnston@cpan.org> - authentication and XML on API v1.0
