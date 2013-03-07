package VMware::vCloud;

use Cache::Bounded;
use Data::Dumper;
use VMware::API::vCloud;
use VMware::vCloud::vApp;
use strict;

our $VERSION = 'VERSIONTAG';

=head1 NAME

VMware::vCloud - VMware vCloud Director

=head1 SYNOPSIS

  my $vcd = new VMware::vCloud ( $hostname, $username, $password, $orgname, { debug => 1 } );  
  my %vapps = $vcd->list_vapps();

  my $vappid = $vapps{'My Personal vApp'};

  my $vapp = $vcd->get_vapp($vappid);
  my $ret = $vapp->power_on();

=head1 DESCRIPTION

This module provides a Perl interface to VMware's vCloud Director.

=head1 EXAMPLE SCRIPTS

Included in the distribution of this module are several example scripts. 
Hopefully they provide an illustrative example of the use of vCloud Director. 
All scripts have their own POD and accept command line parameters in a similar 
way to the VIPERL SDK utilities and vghetto scripts.

	login.pl - An example script that demonstrates logging in to the server.
	org_get.pl - Selects a random organization and prints a Data::Dumper dump of it's information.
	list-vapps.pl - Prints a list of all VMs the user has access to.

=head1 METHODS

=head2 new($host,$user,$pass,$org,$conf)

This method instances the VMware::vCloud object and verifies the user can log
onto the server.

$host, $user, and $pass are required. They should contain the login information
for the vCloud server.

$org and $conf are optional. 

$org is the vCloud Organization to connect to. If $org is not given, the 
default of 'System' is used.

$conf is an optional hasref containing tuneable parameters:

 * debug - set to a true value to turn on STDERR debugging statements.

=cut 

sub new {
  my $class = shift @_;
  our $host = shift @_;
  our $user = shift @_;
  our $pass = shift @_;
  our $org  = shift @_;
  our $conf = shift @_;

  $org = 'System' unless $org; # Default to "System" org

  my $self  = {};
  bless($self,$class);

  our $cache = new Cache::Bounded;

  $self->{api} = new VMware::API::vCloud (our $host, our $user, our $pass, our $org, our $conf);
  $self->{raw_login_data} = $self->{api}->login();

  return $self;
}

### Standard methods

=head2 create_vapp_from_template($name,$vdcid,$tmplid,$netid)

Given a name, VDC, template and network, instantiate the template with the given
settings and other defaults.

Details of the create task will be returned.

=cut

sub create_vapp_from_template {
  my $self = shift @_;
  my $name = shift @_;

  my $vdcid  = shift @_;  
  my $tmplid = shift @_;
  my $netid  = shift @_;
  
  my %template = $self->get_template($tmplid);
  my %vdc = $self->get_vdc($vdcid);

  my @links = @{$vdc{Link}};
  my $url;

  for my $ref (@links) {
    #$url = $ref->{href} if $ref->{type} eq 'application/vnd.vmware.vcloud.composeVAppParams+xml';
    $url = $ref->{href} if $ref->{type} eq 'application/vnd.vmware.vcloud.instantiateVAppTemplateParams+xml';
  }

  my $fencemode = 'bridged'; # bridged, isolated, or natRouted
  my $IpAddressAllocationMode = 'POOL'; # NONE, MANUAL, POOL, DHCP

  # XML to build

my $xml = '<ComposeVAppParams name="'.$name.'" xmlns="http://www.vmware.com/vcloud/v1" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1">
  <InstantiationParams>
    <NetworkConfigSection>
      <ovf:Info>Configuration parameters for logical networks</ovf:Info>
      <NetworkConfig networkName="'.$netid.'">
        <Configuration>
          <ParentNetwork href="'.$netid.'"/> 
          <FenceMode>'.$fencemode.'</FenceMode>
        </Configuration>
      </NetworkConfig>
    </NetworkConfigSection>
  </InstantiationParams>
  <Item>
    <Source href="'.$template{href}.'"/>
    <InstantiationParams>
      <NetworkConnectionSection
        type="application/vnd.vmware.vcloud.networkConnectionSection+xml"
        href="'.$template{href}.'/networkConnectionSection/" ovf:required="false">
        <ovf:Info/>
        <PrimaryNetworkConnectionIndex>0</PrimaryNetworkConnectionIndex>
        <NetworkConnection network="'.$netid.'">
          <NetworkConnectionIndex>0</NetworkConnectionIndex>
          <IsConnected>true</IsConnected>
          <IpAddressAllocationMode>'.$IpAddressAllocationMode.'</IpAddressAllocationMode>
        </NetworkConnection>
      </NetworkConnectionSection>
    </InstantiationParams>

  </Item>
  <AllEULAsAccepted>true</AllEULAsAccepted>
</ComposeVAppParams>';


#  <Item>
#    <Source href="http://vcloud.example.com/api/v1.0/vApp/vm-4"/>
#    <InstantiationParams>
#      <NetworkConnectionSection
#        type="application/vnd.vmware.vcloud.networkConnectionSection+xml"
#        href="http://vcloud.example.com/api/v1.0/vApp/vm-4/
#        networkConnectionSection/" ovf:required="false">
#        <ovf:Info/>
#        <PrimaryNetworkConnectionIndex>0</PrimaryNetworkConnectionIndex>
#        <NetworkConnection network="CRMApplianceNetwork">
#          <NetworkConnectionIndex>0</NetworkConnectionIndex>
#          <IsConnected>true</IsConnected>
#          <IpAddressAllocationMode>DHCP</IpAddressAllocationMode>
#        </NetworkConnection>
#      </NetworkConnectionSection>
#    </InstantiationParams>
#  </Item>
#  <Item>
#    <Source href="http://vcloud.example.com/api/v1.0/vAppTemplate/vappTemplate-114"/>
#  </Item>

#my $ret = $self->{api}->post($url,'application/vnd.vmware.vcloud.composeVAppParams+xml',$xml);

my $xml = '
<InstantiateVAppTemplateParams name="'.$name.'" xmlns="http://www.vmware.com/vcloud/v1" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1" >
	<Description>Example FTP Server vApp</Description>
	<InstantiationParams>
		<NetworkConfigSection>
			<ovf:Info>Configuration parameters for vAppNetwork</ovf:Info>
			<NetworkConfig networkName="vAppNetwork">
				<Configuration>
					<ParentNetwork href="'.$netid.'"/>
					<FenceMode>'.$fencemode.'</FenceMode>
				</Configuration>
			</NetworkConfig>
		</NetworkConfigSection>
	</InstantiationParams>
	<Source href="'.$template{href}.'"/>
</InstantiateVAppTemplateParams>
';

  return $self->{api}->post($url,'application/vnd.vmware.vcloud.instantiateVAppTemplateParams+xml',$xml);
}

=head2 get_org($orgid)

Given an organization id, it returns a hash of data for that organization.

=cut

sub get_org {
  my $self = shift @_;
  my $id   = shift @_;

  my $org = our $cache->get('get_org:'.$id);
  return %$org if defined $org;
  
  my $raw_org_data = $self->{api}->org_get($id);

  my %org;
  $org{description} = $raw_org_data->{Description}->[0];
  $org{name}        = $raw_org_data->{name};

  $raw_org_data->{href} =~ /([^\/]+)$/;
  $org{id} = $1;

  $org{contains} = {};
  
  for my $link ( @{$raw_org_data->{Link}} ) {
    $link->{type} =~ /^application\/vnd.vmware.vcloud.(\w+)\+xml$/;
    my $type = $1;
    $link->{href} =~ /([^\/]+)$/;
    my $id = $1;
    
    next if $type eq 'controlAccess';
    
    $org{contains}{$type}{$id} = $link->{name};
  }

  $cache->set('get_org:'.$id,\%org);
  return %org;
}

=head2 get_template($templateid)

Given an organization id, it returns a hash of data for that organization.

=cut

sub get_template {
  my $self = shift @_;
  my $id   = shift @_;

  my $tmpl = our $cache->get('get_template:'.$id);
  return %$tmpl if defined $tmpl;
  
  my $raw_tmpl_data = $self->{api}->template_get($id);

  my %tmpl = %$raw_tmpl_data;

=head foo
  $tmpl{description} = $raw_org_data->{Description}->[0];
  $tmpl{name}        = $raw_org_data->{name};

  $raw_org_data->{href} =~ /([^\/]+)$/;
  $org{id} = $1;

  $org{contains} = {};
  
  for my $link ( @{$raw_org_data->{Link}} ) {
    $link->{type} =~ /^application\/vnd.vmware.vcloud.(\w+)\+xml$/;
    my $type = $1;
    $link->{href} =~ /([^\/]+)$/;
    my $id = $1;
    
    next if $type eq 'controlAccess';
    
    $org{contains}{$type}{$id} = $link->{name};
  }
=cut

  $cache->set('get_template:'.$id,\%tmpl);
  return %tmpl;
}

=head2 get_vapp($vappid)

Given an vApp id, it returns a vApp object for that vApp.

See the documentation on VMware::vCloud::vApp for full details on this object
type.

=cut

sub get_vapp {
  my $self = shift @_;
  my $href = shift @_;

  my $vapp = our $cache->get('get_vapp:'.$href);
  return $vapp if defined $vapp;

  $vapp = new VMware::vCloud::vApp ( $self->{api}, $href );
  
  $cache->set('get_vapp:'.$href,$vapp);
  return $vapp;
}

=head2 get_vdc($vdcid)

Given an vDC id, it returns a hash of data for that vDC.

=cut

sub get_vdc {
  my $self = shift @_;
  my $id = shift @_;

  my $vdc = our $cache->get('get_vdc:'.$id);
  return %$vdc if defined $vdc;

  my $raw_vdc_data = $self->{api}->vdc_get($id);

  my %vdc;
  $vdc{description} = $raw_vdc_data->{Description}->[0];
  $vdc{name}        = $raw_vdc_data->{name};

  $raw_vdc_data->{href} =~ /([^\/]+)$/;
  $vdc{id} = $1;

  $vdc{contains} = {};
  
  for my $link ( @{$raw_vdc_data->{Link}} ) {
    $link->{type} =~ /^application\/vnd.vmware.vcloud.(\w+)\+xml$/;
    my $type = $1;
    $link->{href} =~ /([^\/]+)$/;
    my $id = $1;
    
    next if $type eq 'controlAccess';
    
    $vdc{contains}{$type}{$id} = $link->{name};
  }
  
  $cache->set('get_vdc:'.$id,$raw_vdc_data);
  return %$raw_vdc_data;
}

=head2 list_networks() | list_networks($vdcid)

This method returns a hash or hashref of network names and IDs.

Given an optional VDCid it will return only the networks available in that VDC.

=cut

sub list_networks {
  my $self = shift @_;
  my $vdcid = shift @_;

  my $networks = our $cache->get("list_networks:$vdcid:");
  return %$networks if defined $networks;

  my %networks;
  my %vdcs = ( $vdcid ? ( $vdcid => 1 ) : $self->list_vdcs() );

  for my $vdcid ( keys %vdcs ) {
    my %vdc = $self->get_vdc($vdcid);
    my @networks = @{$vdc{AvailableNetworks}};
    for my $netblock (@networks) {
      for my $name ( keys %{$netblock->{Network}} ) {
        my $href = $netblock->{Network}->{$name}->{href};
        $networks{$href} = $name;
      }
    }
  }

  $cache->set("list_networks:$vdcid:",\%networks);
  return %networks;
}

=head2 list_orgs()

This method returns a hash or hashref of Organization names and IDs.

=cut

sub list_orgs {
  my $self = shift @_;
  my $orgs = our $cache->get('list_orgs:');

  unless ( defined $orgs ) {
    $orgs = {};
    my $ret = $self->{api}->org_list();
    for my $orgname ( keys %{$ret->{Org}} ) {
      warn "Org type of $ret->{Org}->{$orgname}->{type} listed for $orgname\n" unless $ret->{Org}->{$orgname}->{type} eq 'application/vnd.vmware.vcloud.org+xml';
      $orgs->{$orgname} = $ret->{Org}->{$orgname}->{href};
    }
    $cache->set('list_orgs:',$orgs); 
  }
  
  return wantarray ? %$orgs : $orgs if defined $orgs;
}

=head2 list_templates()

This method returns a hash or hashref of Template names and IDs the user has
access too.

=cut

sub list_templates {
  my $self  = shift @_;
  
  my $templates = our $cache->get('list_templates:');
  return %$templates if defined $templates;

  my %orgs = $self->list_orgs();
  my %vdcs = $self->list_vdcs();
  
  my %templates;
  
  for my $vdcid ( keys %vdcs ) {
    my %vdc = $self->get_vdc($vdcid);
    for my $entity ( @{$vdc{ResourceEntities}} ) {
      for my $name ( keys %{$entity->{ResourceEntity}} ) {
        next unless $entity->{ResourceEntity}->{$name}->{type} eq 'application/vnd.vmware.vcloud.vAppTemplate+xml';
        my $href = $entity->{ResourceEntity}->{$name}->{href};
        $templates{$href} = $name;
      }
    }
  }

  $cache->set('list_templates:',\%templates);
  return %templates;
}

=head2 list_vapps()

This method returns a hash or hashref of Template names and IDs the user has
access too.

=cut

sub list_vapps {
  my $self  = shift @_;
  my $vapps = our $cache->get('list_vapps:');
  
  unless ( defined $vapps ) {
    my %vdcs = $self->list_vdcs();
    
    for my $vdcid ( keys %vdcs ) {
      my %vdc = $self->get_vdc($vdcid);
      for my $entity ( @{$vdc{ResourceEntities}} ) {
        for my $name ( keys %{$entity->{ResourceEntity}} ) {
          next unless $entity->{ResourceEntity}->{$name}->{type} eq 'application/vnd.vmware.vcloud.vApp+xml';
          my $href = $entity->{ResourceEntity}->{$name}->{href};
          $vapps->{$href} = $name;
        }
      }
    }
  }
  
  $cache->set('list_vapps:',$vapps);
  return wantarray ? %$vapps : $vapps if defined $vapps;
}

=head2 list_vdcs() | list_vdcs($orgid)

This method returns a hash or hashref of VDC names and IDs the user has
access too.

The optional argument of an $orgname will limit the returned list of VDCs in 
that Organization.

=cut

sub list_vdcs {
  my $self    = shift @_;
  my $orgname = shift @_;
  my $vdcs = our $cache->get("list_vdcs:$orgname:");

  unless ( defined $vdcs ) {
    $vdcs = {};
    my %orgs = $self->list_orgs();
    %orgs = ( $orgname => $orgs{$orgname} ) if defined $orgname; 
    
    for my $orgname ( keys %orgs ) {
      my %org = $self->get_org($orgs{$orgname});
      for my $vdcid ( keys %{$org{contains}{vdc}} ) {
        $vdcs->{$vdcid} = $org{contains}{vdc}{$vdcid};
      }
    }
  }

  $cache->set("list_vdcs:$orgname:",$vdcs);
  return wantarray ? %$vdcs : $vdcs;
}

=head2 login()

This method is deprecated and will be removed in later releases.

This method roughly emulates the default login action of the API: It returns
information on which organizations are accessible to the user.

It is a synonym for list_orgs() and all details on return values should be
take from that method's documentation.

=cut

sub login {
  my $self = shift @_;
  return $self->list_orgs(@_);
}

1;

__END__

=head1 VERSION

  Version: VERSIONTAG (DATETAG)

=head1 AUTHOR

  Phillip Pollard, <bennie@cpan.org>

=head1 CONTRIBUTIONS

  Stuart Johnston, <sjohnston@cpan.org>

	Significant helpful contrbutions have been made by Mr. Johnston, including
	the proper handling of the authentication header, the layout of modules,
	and proper support for XML encoding.

=head1 DEPENDENCIES

  Cache::Bounded
  VMware::API::vCloud

=head1 LICENSE AND COPYRIGHT

  Released under Perl Artistic License

=cut
