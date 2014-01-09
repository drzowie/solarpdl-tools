/usr/local/bin/perl /usr/local/lib/perl5/5.12.4/ExtUtils/xsubpp  -typemap /usr/local/lib/perl5/5.12.4/ExtUtils/typemap -typemap /usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core/typemap.pdl   eval_209_fbe1.xs > eval_209_fbe1.xsc && mv eval_209_fbe1.xsc eval_209_fbe1.c
cc -c  -I/usr/local/lib/perl5/site_perl/5.12.4/darwin-2level/PDL/Core -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -I/opt/local/include -O3   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\"  "-I/usr/local/lib/perl5/5.12.4/darwin-2level/CORE"   eval_209_fbe1.c
eval_209_fbe1.xs: In function 'pdl_my_cspline_irregular_readdata':
eval_209_fbe1.xs:455: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:455: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:455: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
eval_209_fbe1.xs:460: error: '$xloc' undeclared (first use in this function)
eval_209_fbe1.xs:460: error: (Each undeclared identifier is reported only once
eval_209_fbe1.xs:460: error: for each function it appears in.)
eval_209_fbe1.xs:609: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:609: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:609: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
eval_209_fbe1.xs:763: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:763: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:763: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
eval_209_fbe1.xs:917: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:917: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:917: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
eval_209_fbe1.xs:1071: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:1071: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:1071: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
eval_209_fbe1.xs:1225: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:1225: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:1225: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
eval_209_fbe1.xs:1379: warning: format '%d' expects type 'int', but argument 3 has type 'long int'
eval_209_fbe1.xs:1379: warning: format '%d' expects type 'int', but argument 4 has type 'long int'
eval_209_fbe1.xs:1379: warning: format '%d' expects type 'int', but argument 5 has type 'long int'
make: *** [eval_209_fbe1.o] Error 1
