=head1 Solar::Photosphere::Turbulence -- helper object for Photosphere

=head1 Author, date, no warranty

Copyright 2002, Craig DeForest.  You may modify and distribute this
software under the terms of the Gnu General Public License, available
at http://www.gnu.org and incorporated herein by reference.  You do
not need to agree to the license to use the software -- only to 
modify and distribute it.

This software comes with NO WARRANTY of any kind.

Version 0.1 -- initial hackage, 31-Jan-2002 -- 5-Mar-2002


=head1 Functions

=cut

package Solar::Photosphere::Turbulence;
use PDL;
use PDL::NiceSlice;

@ISA = [];  # no inheritance

=head2 new

Constructor for new turbulence fields

=cut


sub new {
  my($class,$parent, $opt, $prefix) = @_;
  my($me) = {};

  $me->{prefix} = $prefix;
  $me->{parent} = $parent;
  $me->{w} = $parent->{w};
  $me->{h} = $parent->{h};
  $me->{wh}= $parent->{wh};
  $me->{dx}= $parent->{dx};

  $me->{size} =       $opt->{"${prefix}size"} || 0.5;  # radius of granule (Mm)
  $me->{life} =       $opt->{"${prefix}life"} || 600;# seconds 
  $me->{stab} = $opt->{"${prefix}stability"}   || $opt->{"${prefix}stab"} || 2;
  $me->{vari} = $opt->{"${prefix}variability"} || $opt->{"${prefix}vari"} || 4;

  $me->{plonkrate}=   $opt->{"${prefix}plonkrate"} || 
    $parent->{w}*$parent->{h}*$parent->{scale}*$parent->{scale} / 
      $me->{size} / $me->{size} / 3.14159 / $me->{life};

  # Basic divergence: enough to fill the granule in half of its lifetime
  $me->{d0} = 3.14159 * $me->{size} * $me->{size} * 2 / $me->{life}; 
  $me->{sd0} = $me->{d0}*$me->{stab} / $me->{dx} / $me->{dx};

  ##########
  # Spatial fields
  #
  # These are copies of the playing field that contain different quantities

  $me->{id} =    zeroes($me->{w},$me->{h});   # vortex ID
  $me->{vel} =   zeroes($me->{w},$me->{h},2); # 2-D velocity
  $me->{speed} = zeroes($me->{w},$me->{h});   # Speed

  ##########
  # List fields
  #
  $me->{desc}   = {};       # Indexed by vortex number; 
                            #  fields are PDLs containing (x,y,t,n,max_n).
                            # n is number of pixels owned -- if it drops to
                            # zero, or to 1/2 of max_n, the cell vanishes.
  $me->{id1} = 0;  # Start with vortex 0.

  return bless($me,$class);
}
  

# Add a new vortex/whatever to the turbulence field
#

=head2 add

Adds a new element to the turbulence field.  You give the coordinates and
time of birth.

=cut

sub add {
  my($f,$coords,$t) = @_;
  $t = $f->{parent}->{t} unless defined($t);

  my($id) = ++$f->{id1};
  
  $coords .= $coords->clip(1, $f->{wh} - 1);           # Clip coords to fit in field
  $f->{id}->($coords->(0),$coords->(1)) .= $id;        # Seed field
  $f->{desc}->{$id} = $coords->append($t)->append(ones(2));# Add to list of vortices
}

=head2 plonk

Randomly adds new elements to the turbulence field at a boundary of
existing elements.  You just specify the number of elements to drop.

=cut

sub plonk {
  my($me,$n) = @_;
  my($i);
  my($xy);
  my($xy0) = pdl(0,0);
  my($sp) = pdl(0);
  my($vel0) = $me->{vel};
  my($vel) = pdl(0,0);
  my($xstep) = $me->{dx};
  
  for($i=0;$i<$n;$i++) {
    print "." if($PDL::verbose);
    ## Select a place
    $xy = pdl(rand($me->{w}),rand($me->{h}));
    $xy0 .= floor($xy)->clip(0,$me->{wh}-1);
    
    ## Walk ``downhill'' a pixel at a time to the nearest boundary.
    $id0 = $me->{id}->($xy0->(0),$xy0->(1));

    while($id0 && ($me->{id}->($xy0->(0),$xy0->(1)) == $id0)) {
      $dxy = $xy0 - $xy;

      my($x_0,$y_0,$x_1,$y_1,$dx,$dy);
      
      $vel .= $vel0->($xy0->list);
      $sp  .= sqrt(($vel * $vel)->sum);

      last if($sp == 0 || $x_0 == 0 || $x_1==$me->{w}-1 ||
	      $y_0 == 0 || $y_1 == $me->{h}-1);

      $xy += $vel/$sp;
      print "vel=$vel; xy0=$xy0; xy=$xy; id=".$me->{id}->(($xy0->(0)),($xy0->(1)))."\n";
      $xy0 = floor($xy)->clip(0,$me->{wh}-1);
    }
    print "a($xy) " if($PDL::verbose);
    $me->add($xy,$me->{t});
  }
}


=head2 remove

Removes a source from the field

=cut

sub remove {  
  my($f,$sg) = @_;

  my($fd) = $f->{desc}->{$sg};

  my($rr) = floor(max_r($f,$fd)+2) * pdl(-1,1);

  my($xr) = (floor($fd->((0)) + 0.5) + $rr)->clip(0,$f->{w}-1);
  my($yr) = (floor($fd->((1)) + 0.5) + $rr)->clip(0,$f->{h}-1);

  my($fid0) = $f->{id}->($xr->((0)):$xr->((1)),
			 $yr->((0)):$yr->((1)));
    
  (where($fid0->flat,$fid0->flat == $sg)) .= 0;
  delete $f->{desc}->{$sg};
}



=head2 single_flow

Returns the flow field (Vx and Vy) around a single source, given 
its descriptor and an offset location in pixels.  You feed in a 
2x(mumble) PDL containing X and Y offset values in pixels.  On return,
it contains velocity vectors in scientific units.  The return value is a
(mumble) PDL containing the speeds.

The divergence strength formula is  (stab) * (1 + vari * sin(pi * age/life)).
It's clipped above zero, so the divergence should drop to zero shortly after
the age expires.  In order for that to work, vari must be >= 1.

=cut

sub single_flow {
  my($me, $fd, $coords) = @_;
  
  my($t0) = $fd->((2));
  my($rel_age) = ($me->{t} - $t0) / ($me->{life});
  
  # strength gets the current divergence rate of the granule.  
  my($strength) = $me->{sd0} *
    (1 + $me->{vari} * sin(3.14159*(clip($rel_age,0,2)))->clip(0,));

  my($x) = $coords((0));
  my($y) = $coords((1));
  my($r) = sqrt($x*$x + $y*$y)->clip(0.5); # Avoid divide-by-zero at 
                                           # singularity


  # Generate a simple divergence-singularity field and scale by $strength.
  my($out) = zeroes($coords);
  my($vx) = $out->((0));
  my($vy) = $out->((1));

  my($v) = $strength / 3.14159 / $r;
  $vx *= $v / $r;
  $vy *= $v / $r;
  
  return $v;
}

=head2 max_r

Finds the maximum radius of an individual flow field, given its descriptor.
Return value is in pixels.

The formula needs to be coordinated with the one in single_flow -- it's the
integral of the divergence equation.    The sin term (here a cos term) is
simply clipped so that granules found late in life get slightly too-large
radii; but the wastage probably isn't too huge.

=cut

sub max_r {
  my($me,$fd) = @_;
  
  my($t0) = $fd->(2);
  my($age) = $me->{t} - $t0;
  my($rel_age) = pdl($age / $me->{life}) -> clip(0,1);
 
  # 
  # r=\radical[A/pi]
  #
  # A=\integral[dt, stab * d0 * (1 + vari*sin(pi*age/life))]
  #

  my($A) =  $me->{sd0} * 
	       ( ($age) + 
		 ( ($me->{vari} * $me->{life} / 3.14159) *
		   (1 - cos(3.14159 * $rel_age) )
		   )
		 );

  return sqrt($A/3.14159);
	   
}


=head2 update

Calculates the velocity, speed, and turbulence-cell fields and expires 
cells as necessary.  No parameters required.

=cut

sub update {
  my($me) = shift;

  # Clear out the field for recalculation...
  $me->{speed} .= 0;
  $me->{vel} .= 0;
  $me->{id} .= 0;

  # Iterate
  my($cell);
  my($ii) = 0;
  foreach $cell(sort {$a <=> $b} keys %{$me->{desc}}) {
    print "$cell" if($PDL::verbose);

    # Skip cells that get deleted
    next unless(defined($me->{desc}->{$cell})); 

    $ii++;
    print "." unless($ii % 100);

    #Initialize some variables
    my($cd) = $me->{desc}->{$cell};
    my($c_x) = $cd->((0));
    my($c_y) = $cd->((1));
    my($c_t0) = $cd->((2));
    my($c_n) = $cd->((3));
    my($c_maxn) = $cd->((4));
    my($c_age) = $me->{t} - $ct0;

    # Update max size, and obliterate if it's shrinking...
    if($c_n < $c_maxn/2) {
      remove($me,$cell);
      next;
    }
    $c_maxn .= $c_n if($c_n > $c_maxn);


    # Figure out the region of interest around the cell

    my($c_x0) = floor($c_x+0.5);
    my($c_y0) = floor($c_y+0.5);

    print "[max_r=".max_r($me,$cd)."]" if($PDL::verbose);
    my($rr) = pdl(-1,1) * (floor(max_r($me,$cd))+1);
    my($xr) = ($rr + $c_x0)->clip(0,$me->{w}-1);
    my($yr) = ($rr + $c_y0)->clip(0,$me->{h}-1);
    my($slice_str) = $xr->((0)).":".$xr->((1)).",".$yr->((0)).":".$yr->((1));

    print "('$slice_str') " if($PDL::verbose);
    
    my($id_subgrid)  = $me->{id}   -> slice($slice_str);
    my($sp_subgrid)  = $me->{speed}-> slice($slice_str);
    my($vel_subgrid) = $me->{vel}  -> slice($slice_str);

    ##########
    # Generate a local subgrid of coordinates and use it to make speeds
    # and velocities.
    
    my($sm_grid) = (cat(xvals($sp_subgrid)+$xr->((0))-$c_x0,
			yvals($sp_subgrid)+$yr->((0))-$c_y0)
		    ) -> reorder(2,0,1);
    my($speed) = single_flow($me,$cd,$sm_grid);

#    if(!defined $z) {
#      $z = PDL::Graphics::PGPLOT::Window->new('/xw');
#      $z->imag($me->{speed});
#      $z->hold;
#    }
#    do { 
#      my($f) = $me->{speed};
#      $f->slice($slice_str) .= $speed;
#      $z->imag($f);
#    }while(0);

    ##########
    # Find all the pixels that need to be overwritten.
    my($idx) = which($sp_subgrid->flat < $speed->flat);
    print "n_idx:".$idx->nelem." " if($PDL::verbose);

    ##########
    # Remove the current cell if it has no pixels left.
    if( ( ($me->{desc}->{$cell}->((3))) .= $idx->nelem ) == 0) {
      print "!A($cell)" if($PDL::verbose);
      remove($me,$cell);
      next;
    }
    
    print "SET: $cell:".$me->{desc}->{$cell}->((3))." " if($PDL::verbose);
    ##########
    # Find all the stomped IDs and decrement their respective sizes. 
    # If necessary, delete them.
    my $stomp;
    my $sgl = $id_subgrid->flat->($idx);
    for ($sgl->uniq->list) {
      $stomp = $_;
      next unless $stomp;

      my($n0) = $me->{desc}->{$stomp}->((3));
      $n0 -= sum($sgl==$stomp);
      if($n0  <= 0 ) {
	print "!B($cell)" if($PDL::verbose);
	remove($me,$stomp);
      }
    }

    ##########
    # Overwrite the pixels that need it.
    $sgl .= $cell;
    $sp_subgrid->flat->($idx) .= $speed->flat->($idx);

    $vel_subgrid->clump(0..1)->($idx) .= 
      $sm_grid->reorder(1,2,0)->clump(0..1)->($idx);

    print "$cell\n" if($PDL::verbose);

#    $z->imag($me->{id});
  }
}

=head2 evolve 

Evolves the simulation field to a set time in a single step.  An appropriate
number of new cells are plunked down into the grid, and the grid is updated.
This is normally called from Solar::Photosphere::evolve, which handles the 
time steps.

=cut

sub evolve {
  my($me,$t) = @_;

  my($dt) = $t -  $me->{t};

  return if($dt <= 0);

  print "evolve: stepping from ".$me->{t}." to $t...\n" if($PDL::verbose);

  ##########
  # Plonk down new cells
  my($plonk_number) = $me->{plonkrate} * $dt;
  my($plonks) = floor($plonk_number);
  $plonks++ if(rand() < ($plonk_number - $plonks));

  print "evolve: plonking $plonks...\n" if($PDL::verbose);
  plonk($me,$plonks);

  ##########
  # Duct granules in the surrounding field
  if(defined $me->{vel0}) {
    print "evolve: ducting cells...\n" if($PDL::verbose);
    my($vel) = pdl(0,0);
    my($sp)= pdl(0);
    my($x0) = pdl(0,0);
    my($x1) = pdl(0,0);
    my($xstep) = $me->{dx};
    my($vel0) = $me->{vel};

    foreach $cell(sort keys %{$me->{desc}}) {
      
      # Get location and local velocity
      my($t1) = $me->{t};
      my($dt);
      my($nn) = 0;
      do {
#	print "." if($PDL::verbose);
	my($x);
	$x = $me->{desc}->{$cell}->(0:1);
	$x0 .= floor($x)->clip(zeroes(2),$me->{wh}-1);
	$x1 .= ($x0+1)->clip(zeroes(2),$me->{wh}-1);
	
	my($x_0,$y_0,$x_1,$y_1,$dx,$dy);
	($x_0,$y_0) = $x0->list;
	($x_1,$y_1) = $x1->list;
	($dx,$dy) = ($x - $x0)->list;

	$vel .= ($vel0->($x_0,$y_0) * (1 -$dx) * (1 -$dy) + 
		 $vel0->($x_0,$y_1) * (1 -$dx) * (   $dy) + 
		 $vel0->($x_1,$y_0) * (   $dx) * (1 -$dy) + 
		 $vel0->($x_1,$y_1) * (   $dx) * (   $dy)
		 );

	$sp  .= sqrt(($vel * $vel)->sum) / $xstep;

	$dt = ($sp>0) ? min(cat(pdl($t-$t1), pdl(1.0/$sp))) : $t - $t1;

	$x += ($vel / $xstep) * $dt;

#	print "+$dt->$t1"."($t)[$x] " if($PDL::verbose);
	$t1 += $dt;

	if(sum($x->clip(zeroes(2),$me->{wh}-1) != $x)) {
	  print "R" if($PDL::verbose);
	  remove($me,$cell);
	  next;
	}

	$nn++;
      } while($t1 < $t);
      print "[$nn steps] " if($PDL::verbose);
    }
  }

  print "ok" if($PDL::verbose);

  ##########
  # Increment time and find new fields
  $me->{t} = $t;
  
  print "updating...\n" if($PDL::verbose);
  update($me);

  print "\n\n" if($PDL::verbose);
}
  
=head2 seed

Initializes the field with a random set of sources.  Achieved by adding
enough new sources at random locations to fill up the total expected
number of sources in the field.  The ages vary randomly over the
life cycle of the sources, which is slightly broken -- normally age decreases
monotonically with ID.

This distribution is slightly different than you'd get from the normal
evolution, because it's truly random -- new granules arise anywhere, rather
than being ducted to the edges of other ones.  So the simulation takes
a couple of turbulence lifecycles to settle down.

=cut

sub seed {
  my($me) = shift;

  my($i);
  my($expected);

  $expected = $me->{w} * $me->{h} * $me->{dx} * $me->{dx} /
    $me->{size} / $me->{size} * 4 / 3.14159;

  print "me->{w} = $me->{w}; me->{dx}= $me->{dx}\n";
  print "seeding $expected values...\n";
  for ($i=0;$i<$expected;$i++) {
    $me->add( floor(pdl(rand(),rand()) * $me->{wh}), $me->{t} - 2 * rand() * $me->{life} );
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

  my($fno) = sprintf("%4.4d",$me->{parent}->{frame});
  
  my($suffix);
  if($type =~ s/(\.(\w*))$//) {$suffix = $1} else {$suffix = ".fits"};

  if($type =~ m/id/) {
    $fname = "$me->{prefix}_id_${fno}${suffix}";
    $out = ($me->{id})->clip(  min(pdl(keys(%{$me->{desc}})))  );
  }

  else {
    print STDERR 
      "Solar::Photosphere::Turbulence::write_image: unknown type '$type' ignored.\n";
    return;
  }

  wpic($out,$fname);
}
