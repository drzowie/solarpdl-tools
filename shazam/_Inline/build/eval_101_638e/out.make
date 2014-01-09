/usr/local/bin/perl /usr/local/lib/perl5/5.12.4/ExtUtils/xsubpp  -typemap /usr/local/lib/perl5/5.12.4/ExtUtils/typemap -typemap /usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core/typemap.pdl   eval_101_638e.xs > eval_101_638e.xsc && mv eval_101_638e.xsc eval_101_638e.c
cc -c  -I/usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -I/opt/local/include -O3   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\"  "-I/usr/local/lib/perl5/5.12.4/darwin-2level/CORE"   eval_101_638e.c
eval_101_638e.xs: In function 'pdl_my_cspline_irregular_readdata':
eval_101_638e.xs:444: error: '$dex' undeclared (first use in this function)
eval_101_638e.xs:444: error: (Each undeclared identifier is reported only once
eval_101_638e.xs:444: error: for each function it appears in.)
make: *** [eval_101_638e.o] Error 1
