package Corks;

BEGIN {
    package Corks;
    use PDL;
    require Exporter;
    require DynaLoader;
    @ISA = qw(Exporter DynaLoader);
    @EXPORT =();
    bootstrap Corks;
}


1;
