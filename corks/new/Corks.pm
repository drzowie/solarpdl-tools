package Corks;

BEGIN {
    package Corks;
    use PDL;
    require Exporter;
    require DynaLoader;
    @ISA = qw(Exporter DynaLoader);
    @EXPORT = ( qw/ 
    	      	    new_sim
		    sim2str
		    plonk_granule
		    plonk_supergranule
		    sg_ids
		    g_ids
		    update_sim
                 
		 /);
    bootstrap Corks;
}


1;
