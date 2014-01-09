/usr/local/bin/perl /usr/local/lib/perl5/5.12.4/ExtUtils/xsubpp  -typemap /usr/local/lib/perl5/5.12.4/ExtUtils/typemap -typemap /usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core/typemap.pdl   eval_83_3661.xs > eval_83_3661.xsc && mv eval_83_3661.xsc eval_83_3661.c
cc -c  -I/usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -I/opt/local/include -O3   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\"  "-I/usr/local/lib/perl5/5.12.4/darwin-2level/CORE"   eval_83_3661.c
eval_83_3661.xs: In function 'pdl_my_cspline_irregular_readdata':
eval_83_3661.xs:491: error: stray '#' in program
eval_83_3661.xs:491: error: 'end' undeclared (first use in this function)
eval_83_3661.xs:491: error: (Each undeclared identifier is reported only once
eval_83_3661.xs:491: error: for each function it appears in.)
eval_83_3661.xs:491: error: expected ';' before 'of'
eval_83_3661.xs:651: error: stray '#' in program
eval_83_3661.xs:651: error: expected ';' before 'of'
eval_83_3661.xs:811: error: stray '#' in program
eval_83_3661.xs:811: error: expected ';' before 'of'
eval_83_3661.xs:971: error: stray '#' in program
eval_83_3661.xs:971: error: expected ';' before 'of'
eval_83_3661.xs:1131: error: stray '#' in program
eval_83_3661.xs:1131: error: expected ';' before 'of'
eval_83_3661.xs:1291: error: stray '#' in program
eval_83_3661.xs:1291: error: expected ';' before 'of'
eval_83_3661.xs:1451: error: stray '#' in program
eval_83_3661.xs:1451: error: expected ';' before 'of'
make: *** [eval_83_3661.o] Error 1
