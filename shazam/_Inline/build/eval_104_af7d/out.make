/usr/local/bin/perl /usr/local/lib/perl5/5.12.4/ExtUtils/xsubpp  -typemap /usr/local/lib/perl5/5.12.4/ExtUtils/typemap -typemap /usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core/typemap.pdl   eval_104_af7d.xs > eval_104_af7d.xsc && mv eval_104_af7d.xsc eval_104_af7d.c
cc -c  -I/usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -I/opt/local/include -O3   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\"  "-I/usr/local/lib/perl5/5.12.4/darwin-2level/CORE"   eval_104_af7d.c
eval_104_af7d.xs: In function 'pdl_my_cspline_irregular_readdata':
eval_104_af7d.xs:444: error: '$dex' undeclared (first use in this function)
eval_104_af7d.xs:444: error: (Each undeclared identifier is reported only once
eval_104_af7d.xs:444: error: for each function it appears in.)
make: *** [eval_104_af7d.o] Error 1
