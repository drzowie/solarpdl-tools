use ExtUtils::MakeMaker;
my %options = %{       
{
  'TYPEMAPS' => [
    '/usr/local/lib/perl5/5.12.4/ExtUtils/typemap',
    '/usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core/typemap.pdl'
  ],
  'NAME' => 'eval_234_6e13',
  'INC' => '-I/usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core',
  'VERSION' => '0.00'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
