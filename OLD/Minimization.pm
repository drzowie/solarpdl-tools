BEGIN {
use PDL::NiceSlice;

$VERSION = 0.1;
use Exporter;
@EXPORT = qw(simplex);
@EXPORT_OK = qw(simplex);
%EXPORT_TAGS=(Func=>[ qw(simplex) ]);

use Carp;

print "Loading PDL::Minimization...\n" if($PDL::debug);
}

=head1 NAME

PDL::Minimization

=head1 DESCRIPTION

Here are a collection of N-D heuristic minimization routines for PDL.
For now, the collection is pretty, uh, minimal -- it only includes 
simplex.  It's in a separate package (instead of a .pdl file) to hide
some package subroutines.

Data are localized properly so that, for example, you can nest minimizations.

=head1 SYNOPSIS

use PDL::Minimization;  
$y1 = simplex($y0, \&heuristic, $epsilon);


=head1 FUNCTIONS

=head2 simplex -- simplex minimizer

=over 

=item USAGE

   $y1 = simplex( $y0, \&heuristic, $epsilon );

=item DESCRIPTION

simplex finds local minima.  You feed in a heuristic function and an initial 
parameter vector, and it assembles a simplex in parameter space and walks
around using the simplex minimization algorithm in Press et al.  It returns
when the simplex is smaller than $epsilon.  You can specify $epsilon as a 
scalar or as a vector across dimensions of $y.

No provision is made for passing "extra" parameters to the heuristic
function, because you can do that with a closure:
   $out = simplex( $y0, ( sub { gen_heuristic($p1, $p2, @_) } ), $epsilon );
or
   $a = sub { gen_heuristic($p1, $p2, @_) };
   $out = simplex( $y0, $a, $epsilon );

The heuristic function ref is called as follows:
   $val = &$heuristic($y)
where $y is a 1-D input pdl OR a 2-D pdl containing a bunch of input vectors.
(in other words, the heuristic function is assumed to be vectorizable!).

If $y0 is a 1-D pdl, it is regarded as a single vector in parameter space, and
a simplex of side length $epsilon is generated.

If $y0 is a 2-D pdl, it is regarded as an initial simplex.


=item RETURNS

the minimized vector.

=item HISTORY

Written 2-Oct-2001

=cut

sub PDL::Minimization::find_opt {
  my($opt) = {};
  my(@a);
  while(1) { 
    return unless(defined($_ = shift));
    if(ref $_ eq 'HASH') {
      $opt = $_;
      last;
    } 
    push(@a,$_);
  };

  return $opt,@a,@_;
}

*simplex = \*PDL::Minimization::simplex;
sub PDL::Minimization::simplex {
 my ($opt, $y0, $heuristic, $epsilon) = find_opt(@_);

  if(!defined $epsilon) {
    $epsilon = 1e-3;
    print "simplex: setting epsilon to $epsilon by default\n" 
      if($PDL::debug || $opt->{verbose});
  }

  my $n_dims = $y0->dims;                 # n_dims gets number of dimensions passed in
  my $dims = PDL::pdl('PDL',$y0->dims);   # dims gets piddle of $y0's dimensionality
  my $dim = $n_dims>1 ? $dims->(0) : $dims; # gets the dim of the space we're working in

  # Set up initial conditions: process $y0 so that it's a nice simplex.
  # Possibilities:  
  #   * It's a vector -- assemble a simplex
  #   * It's an n x (n+1) matrix -- already a simplex!
  #   * It's an n x 1 matrix -- treat as a vector
  #   * It's none of the above -- barf.


  ## It's an nx1 -- change into a vector
  if($n_dims == 2 && $dims->(1) == 1) {
    $n_dims = 1;
    $y0 = $y0->(,(0));
  }

  if($n_dims == 1) {
    # We got just a single vector -- assemble an n-dimensional simplex of 
    # given side length (or $epsilon).

    my $side;
    if(defined ( $side = $opt->{initial_len} ) ) {  # Try initial_len option
      print "simplex: using options for initial side length\n"
	if($PDL::debug || $opt->{verbose});
    } else {
      $side = &PDL::pdl('PDL',$epsilon)->dummy(-1,$dim);          # Generate equal sides, len epsilon
      print "simplex: using epsilon ($epsilon) fixed initial side length\n"
	if($PDL::debug || $opt->{verbose});
    }
    
    $y0 = $y0->copy + main::zeroes($dim->dummy(-1,3)->dummy(-1,4));
    $y0->(:,1:$dim)->diagonal(0,1) += $side;   # Add offsets
  }
  elsif($n_dims == 2) {
    ## It could be an n x (n+1)
    croak("$y0 must be a vector or a simplex!") if($dims->(1) != $dims->(0)+1);

    ## A more careful person would put a linear independence check here
  }
  else {
    croak ("simplex: $y0 must be an n-vector or an (n x n+1) matrix. (got $n_dim dims)\n");
  }


  print "Finding initial heuristic values...\n" if($PDL::debug || $opt->{verbose});

  ##############################
  # Now $y0 contains the initial simplex.  Get initial heuristic values.
  # (Assume that the heuristic function takes vectorization!)
  my($v0) = &$heuristic($y0);

  ##############################
  # Main simplex loop (see Press et al. for details)
  my($v1,$y1) = ($v0,$y0);

  do {
    my($i);
    my($worst, $bad, $best);
    my($worstI, $badI, $bestI);


    # Note -- this little snippet gives "odd" answers in the fully
    # degenerate case -- but in that case simplex is about to exit anyway.

    # Find worst, second-worst, and best indices
    $worstI = which($v1 == $v1->max);
    if($worstI->nelem > 1) {
      $badI = $worstI->(1);
      $worstI = $worstI->(0);
    }
    else {
      my($v2) = $v1->(which( $v1 < $v1->max ));
      $badI = which( $v2 == $v2->max );
      $badI = $badI->(0) if($badI->nelem > 1);   # Get 0th element
      $badI++ if($badI >= $worstI);              # Account for removed worst element
    }

    $bestI = which($v1 == $v1->min);
    $best = $v1->( (which($v1 == $v1->min) ) );

    ### NEXT:  attempt several motions and settle on the best one.

    } while(0);
}  

## move_simplex scales the ith vertex along the perpendicular to the
## n-plane formed by the other n vertices.  If the scaling factor is negative,
## it reflects, scaling the value.  It keeps the scaling if it improves the
## value of the heuristic.

sub Minimization::move_simplex { }

## scale_simplex scales the simplex around its median point
sub Minimization::scale_simplex { }

## simplex_center finds the median point of the simplex.
sub Minimization::simplex_center { }

1;
