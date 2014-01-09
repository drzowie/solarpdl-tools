/*
 * Corks.xs - code for a C-assisted Corks clas in perl
 * 
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include "pdl.h"
#include "pdlcore.h"

static Core* PDL;
static SV* CoreSV;

/**********************************************************************
 * Include the source code for the C library...
 */
#include "corkslib.c"

/**********************************************************************
 * general helper/interface routines 
 */

pdl *id_pdl_from_field(FIELD *f) {
  pdl *p;
  PDL_Long dims[2];
  PDL_Long *d;
  PDL_Long *dptr;
  long *lptr;
  long i;

  dims[0] = f->w;
  dims[1] = f->h;
  
  p = PDL->create(PDL_PERM);
  PDL->setdims(p, dims, 2);
  p->datatype = PDL_L;
  PDL->allocdata(p);
  PDL->make_physical(p);
  d = p->data;

  lptr = f->id;
  dptr = d;

  for(i=0;i<dims[0] * dims[1]; i++)
    *(dptr++) = *(lptr++);

  return p;
}
 
pdl *v_pdl_from_field(FIELD *f) {
  pdl *p;
  PDL_Long dims[3];
  PDL_Double *d;
  PDL_Double *dptr;
  double *ptr;
  long i;
  
  dims[0] = 2;
  dims[1] = f->w;
  dims[2] = f->h;
  
  p = PDL->create(PDL_PERM);
  PDL->setdims(p, dims, 3);
  p->datatype = PDL_D;
  PDL->allocdata(p);
  PDL->make_physical(p);
  d = p->data;

  ptr = f->V;
  dptr = d;

  for(i=0;i<dims[0] * dims[1] * dims[2]; i++) 
    *(dptr++) = *(ptr++);

  return p;
}

/**********************************************************************
 * XS definitions for the package follow...
 */

MODULE = Corks     PACKAGE = Corks

IV
new_sim(phv)
 HV *phv;
PREINIT:
 WORLD *w;
 SV **svp;
CODE:
 w = new_world(500,500);

 if( (svp = hv_fetch(phv, "dt", 2, 0)) && *svp != &PL_sv_undef )
   w->p->dt = SvNV(*svp);
 
 if( (svp = hv_fetch(phv, "dx", 2, 0)) && *svp != &PL_sv_undef )
   w->p->dx = SvNV(*svp);

 if( (svp = hv_fetch(phv, "w", 1, 0)) && *svp != &PL_sv_undef )
   w->p->w = SvIV(*svp);

 if( (svp = hv_fetch(phv, "h", 1, 0)) && *svp != &PL_sv_undef )
   w->p->h = SvIV(*svp);

 if( (svp = hv_fetch(phv, "g_life", 6, 0)) && *svp != &PL_sv_undef )
   w->p->g_life = SvNV(*svp);

 if( (svp = hv_fetch(phv, "g_size", 6, 0)) && *svp != &PL_sv_undef )
   w->p->g_size = SvNV(*svp);

 if( (svp = hv_fetch(phv, "g_turnover", 10,0)) && *svp != &PL_sv_undef )
   w->p->g_turnover = SvNV(*svp);
 
 if( (svp = hv_fetch(phv, "sg_life", 7, 0)) && *svp != &PL_sv_undef )
   w->p->sg_life = SvNV(*svp);

 if( (svp = hv_fetch(phv, "sg_size", 7, 0)) && *svp != &PL_sv_undef )
   w->p->sg_size = SvNV(*svp);

 if( (svp = hv_fetch(phv, "sg_turnover", 10,0)) && *svp != &PL_sv_undef )
   w->p->sg_turnover = SvNV(*svp);

 if( (svp = hv_fetch(phv, "em_rate", 7, 0)) && *svp != &PL_sv_undef )
   w->p->em_rate = SvNV(*svp);
 
 if( (svp = hv_fetch(phv, "cork_size", 9, 0)) && *svp != &PL_sv_undef )
   w->p->cork_size = SvNV(*svp);

 if( (svp = hv_fetch(phv, "cork_B", 6, 0)) && *svp != &PL_sv_undef )
   w->p->cork_B == SvNV(*svp);

 update_params(w); 

 RETVAL = (IV)w;
OUTPUT:
 RETVAL



char *
sim2str(wi)
 IV wi;
PREINIT:
 WORLD *w;
 char buf[1024*1024];
 char line[1024*10];
 char *s;
CODE:
 w = (WORLD *)wi;

 *buf = 0; 
 sprintf(line,"WORLD\n");
 strcat(buf,line);
 
 sprintf(line,"## %d supergranules\n## %d granules\n## %d corks\n",
	 w->sgc->maxn - w->sgc->unused ,
	 w->gc->maxn - w->gc->unused ,
	 w->mc->maxn - w->mc->unused );
 strcat(buf,line);

 sprintf(line,"dt\t%g\ndx\t%g\nw\t%d\nh\t%d\ng_life\t%g\ng_size\t%g\n\nsg_life\t%g\nsg_size\t%g\nem_rate\t%g\ncork_size\t%g\ncork_B\t%g\n",
	 w->p->dt,
	 w->p->dx,
	 w->p->w,
	 w->p->h,
	 w->p->g_life,
	 w->p->g_size,
	 w->p->sg_life,
	 w->p->sg_size,
	 w->p->em_rate,
	 w->p->cork_size,
	 w->p->cork_B
	 );
 strcat(buf,line);

 sprintf(line,"\n\ng_plonkrate\t%g\n",w->gc->plonkrate);
 strcat(buf,line);

 RETVAL = buf;
OUTPUT:
 RETVAL

void
plonk_granule(wi, x, y, deltat=0)
 IV wi;
 IV x;
 IV y;
 NV deltat;
CODE:
 new_granule((WORLD *)wi, x, y, deltat);

void
plonk_supergranule(wi, x, y, deltat=0)
 IV wi;
 IV x;
 IV y;
 NV deltat;
CODE:
 new_supergranule((WORLD *)wi, x, y, deltat);

SV *
sg_ids(wi)
 IV wi;
PREINIT:
 pdl *p;
CODE:
 p = id_pdl_from_field( ((WORLD *)wi)->sg );
 RETVAL = NEWSV(546,0); // 546 is arbitrary
 PDL->SetSV_PDL(RETVAL, p);
OUTPUT:
 RETVAL


SV *
g_ids(wi)
 IV wi;
PREINIT:
 pdl *p;
CODE:
 p = id_pdl_from_field( ((WORLD *)wi)->g );
 RETVAL = NEWSV(546,0); // 546 is arbitrary
 PDL->SetSV_PDL(RETVAL, p);
OUTPUT:
 RETVAL

SV *
render_mag(wi)
 IV wi;
PREINIT:
 pdl *p;
 PDL_Long dims[2];
 PDL_Double *d;
 long i;    
 WORLD *w;
CODE:
 w = (WORLD *)wi;
 dims[0] = w->p->w;
 dims[1] = w->p->h;
 
 p = PDL->create(PDL_PERM);
 PDL->setdims(p, dims, 2);
 p->datatype = PDL_D;
 PDL->allocdata(p);
 PDL->make_physical(p);
 d = p->data;
 
 for(i=0; i<w->p->w * w->p->h; i++)
   d[i] = 0;

 for(i=0; i<w->mc->maxn; i++) {
   if(w->mc->array[i].id) {
      long x,y, of;
      x = w->mc->array[i].x;
      y = w->mc->array[i].y;
      of = ( (x>0) ? (x<w->p->w) ? x : w->p->w - 1 : 0) + 
      ( (y>0) ? (y<w->p->h) ? y : w->p->h - 1 : 0)*(w->p->w);
      d[of] += (w->mc->array[i].id > 0) ? 1 : -1;
   }
 }

 RETVAL = NEWSV(547,0); // 547 is arbitrary
 PDL->SetSV_PDL(RETVAL, p);
OUTPUT:
 RETVAL

 	

void
update_sim(wi,n=1)
 IV wi
 IV n
CODE:
 update_sim((WORLD *)wi, n);

BOOT:
/**********************************************************************
 **** bootstrap code -- load-time dynamic linking to pre-loaded PDL
 **** modules and core functions.   **/
 perl_require_pv("PDL::Core");
 CoreSV = perl_get_sv("PDL::SHARE",FALSE);
 if(CoreSV==NULL)     Perl_croak(aTHX_ "Can't load PDL::Core module (required by Flux::Fluxon)");

 PDL = INT2PTR(Core*, SvIV( CoreSV ));  /* Core* value */
 if (PDL->Version != PDL_CORE_VERSION)
    Perl_croak(aTHX_ "Flux needs to be recompiled against the newly installed PDL");
