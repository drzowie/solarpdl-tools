=head1 NAME

PDL::List -- lists implemented as PDLs

=head1 DESCRIPTION

Sometimes you want to represent a list of objects whose internal data 
is only numeric, and to act on them in parallel -- for example, within a 
particle hydrodynamic simualtion where particles may be created and 
destroyed.  Then perl hashes work well, but come with some overhead
because you can only deal with the particles one at a time.  PDLs don't
quite work either because they're easier to use for fixed-size structures.

Enter PDL::List -- it implements a list of objects (not all of which are
defined) as a 2-D PDL.  The first dimension is the list enumeration direction,
and the second is the index direction for internal variables.  The 0th
index of the index direction tells you whether a given object is defined or
no, and the remaining values contain numeric values that you store.  

PDL::Lists are pretty simpleminded and are intended for not-too-sparse
lists where the memory wastage from an array representation isn't too bad.
The internal storage is as a large PDL that is reallocated as necessary and
grows by doubling in size each time more space is needed.

The enumeration direction is notionally offset from zero so that you can 
use different portions of the number line -- in a particle hydro code, 
for example, you can just allocate new particles at the top of the used
section of the number line.

PDL::List objects are implemented as hashes with PDL fields; all the 
methods are also accessible as fields in the hash, too, so that you can
avoid the method-call overhead.  If you use PDL operations directly on the
PDL::List object you must offset slices by the value of ->{i0}, which is a 
generic number line offset.

=head1 Author, copyright, no warranty

Copyright 2002, Craig DeForest.

This code may be distributed under the same terms as Perl itself
(license available at http://ww.perl.org).  Copying, reverse
engineering, distribution, and modification are explicitly allowed so
long as this notice is preserved intact and modified versions are
clearly marked as such.

This package comes with NO WARRANTY.

=head1 FUNCTIONS

=cut

  package PDL::List;

BEGIN{
  use Exporter ();

  $PDL::List::VERSION = 0.1;
  @PDL::List::ISA = ( Exporter PDL ) ;
  @PDL::List::EXPORT_OK = ();
  @PDL::List::EXPORT    = ();
  %PDL::List::EXPORT_TAGS = ();
}

=head2 new

Create a new list

=for usage

  $l = new PDL::List(<n_indices>,[<initial_size>]);

=for description

  Allocate a new list with n indices.  The indices will run 1..n in the
  0th dimension of the resulting PDL; the 0th index is used for whether the
  element is defined or no.

For example, if you say:
  
  $data = xvals(2,3)+10*yvals(2,3);
  $a = new PDL::List(2,3);

then

  $a->(1:2,:) .= $data;  $a->(0,:) .= 1;

works the same as:
 
  $a->index(xvals(3)) .= $data;

=cut







  

  

