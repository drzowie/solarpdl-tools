=head1 Solar::Photosphere -- a model photosphere object

=head1 SYNOPSIS

  use Solar::Photosphere;
  
  $a = Solar::Photosphere->new({options});
  ..

=head1 DESCRIPTION

Solar::Photosphere implements a model solar photosphere with flow.
It's the successor to the corks() non-OO solar model, and is (hopefully)
more modular.  It's also (even more hopefully) faster...

A collection of subclasses exist to handle granulation flows, 
cork motion, and such.

=head1 Author, date, no warranty

Copyright 2002, Craig DeForest.  You may modify and distribute this
software under the terms of the Gnu General Public License, available
at http://www.gnu.org and incorporated herein by reference.  You do
not need to agree to the license to use the software -- only to 
modify and distribute it.

This software comes with NO WARRANTY of any kind.

Version 0.1 -- initial hackage, 31-Jan-2002

=head1 FUNCTIONS
=cut

package Solar::Photosphere;
use Solar::Photosphere::Turbulence;

use strict;
use Carp;
use PDL;
use PDL::Graphics::PGPLOT;
use PDL::Graphics::PGPLOT::Window;


use vars qw($VERSION @ISA);
$VERSION = 0.1;
@ISA = ();                   # Base class without inheritance -- name space
                             # is for classification only.

=head2 new

Constructor.  Performs rudimentary initialization of the data structures
but you should  call the other initializers manually.

=over 3

=item Synopsis
    
  $a = new Solar::Photosphere(<size>,<scale>,<options>)

  <size>: A PDL the same size as the playing field or an array ref containing
  the two dimensions (w,h).

  <scale>: A PDL containing the pixel size, in Mm

  <options>: A hash ref containing keyword parameters

=back

=cut

sub new {
  my($i);
  my($opt) = {};
  for($i=0;$i<=$#_;$i++){
    print $i," ";
  }
  my($class,$size,$scale) = @_;

  # Copy options hash
  my(%zz) = %{$opt};
  my($options) = \%zz;

  if(ref $options != 'HASH') {
    die "Usage: Solar::Photosphere::new(<class>,{options});\n";
  }

  ## Set up default options 

  $options->{sg_size} = 15            unless($options->{sg_size});
  $options->{sg_life} = 1.5*60*60*24  unless($options->{sg_life});
  $options->{sg_stability} = 4        unless($options->{sg_stability});
  
  $options->{g_size} = 0.5            unless($options->{g_size});
  $options->{g_life} = 600            unless($options->{g_life});

  $options->{benchmark} = ['g_id','sg_id','vel'] unless($options->{benchmark});

  ## Initialize self

  my($me) = {};

  $me->{dims} = $size || $options->{dims} || [300,300];
  $me->{w} = $me->{dims}->[0];
  $me->{h} = $me->{dims}->[1];
  $me->{wh} = pdl($me->{dims});

  $me->{dx} = $me->{scale} = $scale || $options->{scale} || $options->{dx} || 0.1;
  $me->{dt} = $options->{dt}      || 60;
  $me->{t} = $options->{t}        || 0;

  $me->{vel} = zeroes($me->{w},$me->{h});

  $me->{em_rate} = $options->{em_rate};

  $me->{gfield} = new Solar::Photosphere::Turbulence ($me,$options,'g_');
  $me->{sgfield}= new Solar::Photosphere::Turbulence ($me,$options,'sg_');

#  $me->{gfield}->{vel0} = $me->{sgfield}->{vel};

  $me->{benchmark} = $options->{benchmark};
  
  
  return bless($me,$class);
}

=head2 benchmark

Produce benchmarks for the current object

=cut  
sub benchmark {
  my($me) = shift;
  
  local($_);
  foreach (@{$me->{benchmark}}){
    if(m/(\w+)\_(.*)/) {
      $me->{$1}->write_image($2);
    }
    
    $me->write_image($_);
  }
}


=head2 write_image
  
Writes out a particular type of image to disk, based on prefix and
frame number.  

=cut

sub write_image {
  my($me,$type) = @_;
  my($fname);
  my($out);

  my($fno) = sprintf("%4.4d",$me->{frame});

  my($suffix);
  if($type =~ s/(\.(\w*))$//) {$suffix = $1} else {$suffix = ".fits"};

  if($type =~ /sp(eed)?/i) {
    $fname = "sp_${fno}${suffix}";
    $out = ($me->{vel}*$me->{vel})->reorder(2,0,1)->sumover->sqrt;
  }

  else {
    print STDERR 
      "Solar::Photosphere::write_image: unknown image type '$type'\n";
    return;
  }

  wpic($out,$fname);
}

=head2 evolve

Evolve the fields and advance time...

=cut

sub evolve {
  my($me,$t) = @_;
  my($t1);
  my($z);

  $z = pgwin(Dev=>'/xs');
  $z->imag($me->{gfield}->{id},{Pix=>1});
  $z->hold;

  while($me->{t} < $t) {
    $t1 = $me->{t} + $me->{dt};

    print "Photosphere::evolve:  supergranules to $t1 (final: $t)...\n" ;
    $me->{sgfield}->evolve($t1);
    print "Photosphere::evolve:  granules to $t1 (final: $t)...\n" ;
    $me->{gfield}->evolve($t1);

    # Combine the velocity fields...
    $me->{vel} .= $me->{sgfield}->{vel} + $me->{gfield}->{vel};

    $me->benchmark();
    
    $z->imag($me->{gfield}->{id});

    $me->{frame}++;
    $me->{t} = $t1;
    print "\n\n";
  }
}


1;




