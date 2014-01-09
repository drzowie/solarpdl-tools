#include "corkslib.h"
#include <stdio.h>
#include <stdlib.h>

#define CORKS_DEBUG 0

static const double pi  = 3.1415926536;
static const double pi2 = 3.1415926536/2;
static const double pi4 = 3.1415926536/4;
/**********************************************************************
 * corks.c 
 * 
 * A convective photospheric model implementing a photosphere 
 * and cork sampling.  
 * 
 * Implements a dual-scale irrotational convective model of the surface 
 * of the Sun.  Convective cells are implemented as divergence
 * singularities that expand through a pixel map, until they encounter 
 * either a maximum radius or a stronger flow.  Small convective cells 
 * ('granules') are themselves advected in the flow field of the larger
 * convective cells ('supergranules'). 
 * 
 * The world consists of a large array containing flow-center ID and 
 * velocity, and a collection of points.  
 * 
 * These are pretty much all utility routines; the meat is in Corks.xs and 
 * Corks.pm.
 * 
 * This file is #included into Corks.xs; pretty cheesy but it works...
 * 
 */


/**********************************************************************
 * new_field - constructor.  (zero the field).
 */
FIELD *new_field(long w, long h) {
  long siz = w * h;
  FIELD *f;
  f = (FIELD *)malloc(sizeof(FIELD));
  f->w = w;
  f->h = h;
  f->V = 0;
  f->id = 0;

  f->V  = (double *) malloc(sizeof(double) * siz * 2);
  f->id = (long *)   malloc(sizeof(long)   * siz );

  zero_field(f);

  return f;
}


/**********************************************************************
 * free_field - freer...
 */
void free_field(FIELD *f) {
  if(f->V)
    free(f->V);
  if(f->id)
    free(f->id);
  free(f);
}

/**********************************************************************
 * zero_field - initializer...
 */
void zero_field(FIELD *f) {
  long i;
  long end;
  double *dp;
  long *lp;

  end = f->w * f->h;
  dp = f->V;
  lp = f->id;

  for(i=0;i<end;i++) {
    *(dp++) = 0;
    *(lp++) = 0;
  }
}

/**********************************************************************
 * cork_cp - copy cork info into a dest
 */
void cork_cp(CORK *dest, CORK *src) {
  dest->id = src->id;
  dest->x = src->x;
  dest->y = src->y;
  dest->t_born = src->t_born;
  dest->max_pixels = src->max_pixels;
  dest->rmax_pix = src->rmax_pix;
}
 
/**********************************************************************
 * new_corks - constructor. 
 */
CORKS *new_corks(long size) {
  CORKS *cs = (CORKS *)malloc(sizeof(CORKS));
  cs->size = 0;
  cs->maxn = 0;
  cs->unused = 0;
  cs->array = 0;
  corks_grow(cs, size);
}


/**********************************************************************
 * free_corks - destructor.
 */
void free_corks(CORKS *cs) {
  if(cs->array) {
    free(cs->array);
  }
  free(cs);
}

/**********************************************************************
 * grow_corks - increase target size
 */
void corks_grow(CORKS *cs, long size) {
  CORK *new_array;
  long i;
  long j;
  
  new_array = (CORK *)malloc(sizeof(CORK) * size);
  for(j=i=0;i<cs->maxn;i++) {
    if(cs->array[i].id)
      cork_cp(new_array + (j++), cs->array + i);
  }
  cs->maxn = j;
  cs->unused = 0;
  cs->size = size;
  for(;j<size;j++) {
    new_array[j].id = 0;
  }

  if(cs->array)
    free(cs->array);
  cs->array = new_array;
}

/**********************************************************************
 * add_cork - put another cork on the end
 */
void corks_add_cork(CORKS *cs, CORK *c) {

  if( cs->maxn >= cs->size )
    corks_crunch_and_grow(cs);
  
  cork_cp(cs->array + cs->maxn, c);
  cs->maxn++;
}

/**********************************************************************
 * corks_delete_cork(CORKS *cs, CORK *c)
 */
void corks_delete_cork(CORKS *cs, long pos) {
  cs->array[pos].id = 0;
  cs->unused++;
}

/**********************************************************************
 * corks_crunch_and_grow(CORKS *cs)
 */
void corks_crunch_and_grow(CORKS *cs) {
  long i,j;

  /* If enough elements are used,, grow -- which crunches automatically. */
  if( (cs->maxn - cs->unused) * 3 / 2   >=  cs->size ) {
    corks_grow(cs, cs->maxn * 3 / 2 + 10);
  } else 
    /* If there's empty space, crunch it out */
    if(cs->unused) {
      for( i=0, j=cs->maxn-1 ;
	   i<j;
	   i++ ) {
	if( cs->array[i].id==0 ) {
	  while(cs->array[j].id==0 && j>i) 
	    j--;
	  if(j>i) {
	    cork_cp(cs->array + i,
		    cs->array + j);
	    cs->array[j].id = 0;
	    j--;
	  } else {
	    i--;
	  }
	}
      }
      if( i != cs->maxn - cs->unused ) {
	fprintf(stderr,"corks_crunch_and_grow: assertion failed - i=%d, should be %d (maxn=%d, unused=%d)\n\tProceeding anyway...",i,cs->maxn-cs->unused, cs->maxn, cs->unused);
      }
      cs->maxn = i;
      cs->unused = 0;
    }
}
     
/**********************************************************************
 * new_params - allocate new params structure, populate with default values
 */
PARAMS *new_params() {
  PARAMS *p = (PARAMS *)malloc(sizeof(PARAMS));
  p->dt = 60;              // seconds
  p->dx = 0.1;             // Mm per pixel
  p->w  = 1000;            // 1000 pixels across
  p->h  = 1000;            // 1000 pixels tall
  p->g_life = 600;         // seconds (Spruit et al. 1990)
  p->g_size = 1;           // Mm (used to calculate plonk rate)
  p->g_turnover = 3;       // three turns (guess)
  p->sg_life = 1.5*86400;  // 1.5 days in seconds (Hagenaar et al. 1997)
  p->sg_size = 15;         // Megameters (Hagenaar et al. 1997)
  p->sg_turnover = 3;      // three turns (guess)
  p->em_rate = 1;          // corks per granule, on average
  p->cork_size=0.05;       // nominal radius of corks (Mm)
  p->cork_B=1000;          // nominal magnetization of each cork (1kG)
  return p;
}

void free_params(PARAMS *p) {
  free(p);
}

/**********************************************************************
 * new_world - constructor
 */
WORLD *new_world(long w, long h) {
  WORLD *wld = (WORLD *)malloc(sizeof(WORLD));
  wld->sg = 0;
  wld->g =  0;
  wld->tot= 0;
  wld->sgc = new_corks(100);
  wld->gc = new_corks(10000);
  wld->mc = new_corks(10000);
  wld->next_label = 1;
  wld->next_clabel = 1;
  wld->p = new_params();
  wld->p->w = w;
  wld->p->h = h;
  wld->t = 0;

  update_params(wld);

  return wld;
}

void free_world(WORLD *w) {
  free_params(w->p);
  free_corks(w->mc);
  free_corks(w->gc);  
  free_corks(w->sgc);
  free_field(w->tot);
  free_field(w->g);
  free_field(w->sg);
  free(w);
}

/**********************************************************************
 * update_params recalculates the various, er, calculated parameters 
 * for the individual corks fields.
 */
void update_params(WORLD *wld) {
  PARAMS *p = wld->p;
  double area;
  
  area = p->dx * p->dx * p->w * p->h;

  wld->mc->life = 0;
  wld->mc->corksize  = p->cork_size;
  wld->mc->turnover  = 0;
  wld->mc->div       = 0;
  wld->mc->plonkrate = ( area                              // physical area
			 / (pi4 * p->g_size * p->g_size )  // granular area
			 * p->em_rate                      // emergences per granule
			 / p->g_life                       // granular lifetime
			 );
  wld->mc->plonktime = wld->t;
  
  wld->gc->life      = p->g_life;
  wld->gc->corksize  = p->g_size;
  wld->gc->turnover  = p->g_turnover;
  wld->gc->div       = p->g_turnover * p->g_size * p->g_size / p->g_life;
  wld->gc->plonkrate = ( area / (pi4 * p->g_size * p->g_size) / p->g_life);
  wld->gc->plonktime = wld->t;

  wld->sgc->life      = p->sg_life;
  wld->sgc->corksize  = p->sg_size;
  wld->sgc->turnover  = p->sg_turnover;
  wld->sgc->div       = p->sg_turnover * p->sg_size * p->sg_size / p->sg_life;
  wld->sgc->plonkrate = (area / (pi4 * p->sg_size * p->sg_size) / p->sg_life);
  wld->sgc->plonktime = wld->t;

  if(wld->sg)
    free(wld->sg);
  wld->sg = new_field(p->w, p->h);

  if(wld->g)
    free(wld->g);
  wld->g = new_field(p->w, p->h);

  if(wld->tot)
    free(wld->tot);
  wld->tot = new_field(p->w, p->h);

}

/**********************************************************************
 **********************************************************************
 ****
 **** End of data structure manipulation library - real stuff here...
 ****
 ****/


/**********************************************************************
 *** magnetic cork adder (trivial)
 */
void new_mag_cork(WORLD *w, double x, double y, int negative) {
  CORK mc;
  mc.id = w->next_clabel++;
  if(negative < 0)
    mc.id *= -1;
  mc.x = x;
  mc.y = y;
  mc.t_born = w->t;
  mc.max_pixels = 0;
  mc.rmax_pix = 0;
  corks_add_cork(w->mc, &mc);
}

/**********************************************************************
 *** Create a new bipole.  The 'deltat' argument is ignored, but included
 *** for automated calling from a more general purpose plonker that can
 *** also call new_granule and new_supergranule.
 */

void new_mag_bipole(WORLD *w, double x, double y, double deltat) {
  double theta, xof, yof;
  long of;
  long id;
  long i;

  // bounds check
  if(  x < -0.5 || 
       x >= w->p->w - 0.5 ||
       y < -0.5 || 
       y >= w->p->h - 0.5
       )
    return;

  // Find offset into field array
  of = (long)(xof + 0.5) + (long)(yof + 0.5) * (w->p->w);

  id = w->g->id[of];
  if(id) {
    // if we're in a granule, emerge the bipole in the center of the granule
    for(i=0;i<w->gc->maxn && w->gc->array[i].id != id; i++)
      ;

    if(w->gc->array[i].id != id) 
      fprintf(stderr,"This should never happen -- missed a granule ID (%d) when plonking a bipole! (x=%g,y=%g,of=%d)\n",id,x,y,of);
    
    x = w->gc->array[i].x;
    y = w->gc->array[i].y;
  }    
  
  // Create a bipole with random orientation and separation of 4 cork sizes...
  theta = (random() & 0xffffff)/(double)(0x1000000) * pi * 2;
  xof = w->p->cork_size * 2 * cos(theta);
  yof = w->p->cork_size * 2 * sin(theta);
  
  new_mag_cork(w, x+xof, y+yof,  1);
  new_mag_cork(w, x-xof, y-yof, -1);
}
  
  
  

/**********************************************************************
 *** create/destroy granules
 */
void new_granule(WORLD *w, double x, double y, double deltat) {
  long id = w->next_label++;
  long i,j;
  CORK g;

  // Seed the field with the granule.
  for(i = (x>0)?x-1:0;
      i<= x+1 && i< w->g->w;
      i++) {
    for( j = (y>0)?y-1:0;
	 j<= y+1 && j< w->g->h;
	 j++) {
      long of = j*w->g->w + i;
      w->g->id[ of ] = id;
      w->g->V[ 2 * of    ] = 0;
      w->g->V[ 2 * of +1 ] = 0;
    }
  }

  g.id = id;
  g.x = x;
  g.y = y;
  g.t_born = w->t + deltat;

  g.max_pixels = 0;
  g.rmax_pix = 0;

  corks_add_cork(w->gc, &g);
}

void remove_granule(WORLD *w, long pos) {
  CORK *gc = w->gc->array + pos;
  long id = gc->id;
  FIELD *f = w->g;
  long hits,total_pixels;

  // Remove the granule from the simulation field
  // Expand in successive squares around the center of the 
  // granule, until we get no hits.
  long r = 0;
  printf("  removing %d..."); fflush(stdout);
  total_pixels = 0;
  do {
    long i, of;
    long xmin, xmax, ymin, ymax;

    hits = 0;

    xmin = (gc->x >= r)       ? (gc->x - r) : 0;
    xmax = (gc->x + r < f->w) ? (gc->x + r) : f->w - 1;
    ymin = (gc->y >= r)       ? (gc->y - r) : 0;
    ymax = (gc->y + r < f->h) ? (gc->y + r) : f->h - 1;

    for( i=xmin; i<= xmax; i++ ){
      of = i + ymax * f->w;
      if( f->id[ of ] == id ) {
	f->id[ of ] = 0;
	hits++;
      }

      of = i + ymin * f->w;
      if( f->id[ of ] == id ) {
	f->id[ of ] = 0;
	hits++;
      }
    }
    
    for( i=ymin; i<=ymax; i++) {
      of = i * f->w + xmin;
      if( f->id[ of ] == id) {
	f->id[ of ] = 0;
	hits++;
      }
      
      of = i * f->w + xmax;
      if( f->id[ of ] == id) {
	f->id[ of ] = 0;
	hits++;
      }
    }
    
    r++;
    total_pixels += hits;
  } while(hits);
  printf("%d pixels\n",total_pixels);

  // Now delete the record of the granule from the list.
  corks_delete_cork( w->gc, pos);
}

/**********************************************************************
 **********************************************************************
 *** supergranule add/delete routines
 ***
 */
void new_supergranule(WORLD *w, double x, double y, double deltat) {
  long id = w->next_label++;
  long i,j;
  CORK sg;

  // Seed the field with the granule.
  for(i = (x>0)?x-1:0;
      i<= x+1 && i< w->sg->w;
      i++) {
    for( j = (y>0)?y-1:0;
	 j<= y+1 && j< w->sg->h;
	 j++) {
      long of = j*w->sg->w + i;
      w->sg->id[ of ] = id;
      w->sg->V[ 2 * of    ] = 0;
      w->sg->V[ 2 * of +1 ] = 0;
    }
  }

  sg.id = id;
  sg.x = x;
  sg.y = y;
  sg.t_born = w->t + deltat;
  sg.max_pixels = 0;
  sg.rmax_pix = 0;

  corks_add_cork(w->sgc, &sg);
}

void remove_supergranule(WORLD *w, long pos) {
  CORK *sgc = w->sgc->array + pos;
  long id = sgc->id;
  FIELD *f = w->sg;
  long hits;
  
  // Remove the granule from the simulation field
  // Expand in successive squares around the center of the 
  // granule, until we get no hits.
  long r = 0;
  do {
    long i, of;
    long xmin, xmax, ymin, ymax;

    hits = 0;

    xmin = (sgc->x >= r)       ? (sgc->x - r) : 0;
    xmax = (sgc->x + r < f->w) ? (sgc->x + r) : f->w - 1;
    ymin = (sgc->y >= r)       ? (sgc->y - r) : 0;
    ymax = (sgc->y + r < f->h) ? (sgc->y + r) : f->h - 1;

    for( i=xmin; i<= xmax; i++ ){
      of = i + ymax * f->w;
      if( f->id[ of ] == id ) {
	f->id[ of ] = 0;
	hits++;
      }

      of = i + ymin * f->w;
      if( f->id[ of ] == id ) {
	f->id[ of ] = 0;
	hits++;
      }
    }
    
    for( i=ymin; i<=ymax; i++) {
      of = i * f->w + xmin;
      if( f->id[ of ] == id) {
	f->id[ of ] = 0;
	hits++;
      }
      
      of = i * f->w + xmax;
      if( f->id[ of ] == id) {
	f->id[ of ] = 0;
	hits++;
      }
    }
  } while(hits);

  // Now delete the record of the granule from the list.
  corks_delete_cork( w->sgc, pos);
}


/**********************************************************************
 * plonk_corks
 * 
 * Drop new corks into the simulation according to the plonk_time...
 */
void plonk_corks( WORLD *wld, CORKS *corks, void (*new_cork)(WORLD *w, double x, double y, double deltat) ) {
  double rel_dt;
  double x,y;

  rel_dt = (wld->t - corks->plonktime) * corks->plonkrate;


  //  printf("%g plonks...",rel_dt); fflush(stdout);

  for( rel_dt = (wld->t - corks->plonktime) * corks->plonkrate;
       rel_dt >= 1; 
       rel_dt--
       ) {
    
    // Plonk a cork...
    x = (random() & 0xfffffff)/(double)(0x10000000) * wld->p->w;
    y = (random() & 0xfffffff)/(double)(0x10000000) * wld->p->h;
    (*new_cork)(wld, x, y, - rel_dt / corks->plonkrate );
  }

  // Put the residual back into the plonktime.
  corks->plonktime = wld->t - rel_dt / corks->plonkrate;
  //  printf("\n");
}
  

/**********************************************************************
 * interpolate_vel
 * Get an interpolated velocity from a field
 */
void interpolate_vel(double out[2], FIELD *f, double loc[2]) {
  long x,y;
  double alpha,beta;
  double fac;
  long of;
  
  x = loc[0];
  y = loc[1];
  
  if(x<=0 || y<=0 || x >= f->w-1 || y >= f->h-1) {
    out[0] = 0;
    out[1] = 0;
    return;
  }

  x = loc[0];
  y = loc[1];
  alpha = loc[0] - x;
  beta = loc[1] - y;
  //  printf("alpha=%g, beta=%g\n",alpha,beta);
  of = 2 * (x + y*f->w);
  
  fac = (1 - alpha) * (1 - beta);
  out[0] = fac * f->V[ of ];
  out[1] = fac * f->V[ of + 1];

  of += 2;
  fac = (alpha) * (1 - beta);
  out[0] += fac * f->V[ of ];
  out[1] += fac * f->V[ of + 1 ];
  
  of += f->w - 2;
  fac = (1 - alpha) * (beta);
  out[0] += fac * f->V[ of ];
  out[1] += fac * f->V[ of + 1 ];
  
  of += 2;
  fac = alpha * beta;
  out[0] += fac * f->V[ of ];
  out[1] += fac * f->V[ of + 1 ];
}  
  
/**********************************************************************
 *
 */

 
/**********************************************************************
 * advect_cork
 * Advance a cork by the specified dt through an existing flow field.
 * 
 * returns 0 on normal completion; 1 on motion out-of-bounds.
 */
int advect_cork( CORK *c, FIELD *f, double dt, double dx ) {
  double xy[2];
  double vel[2];
  long i;
  double ddt = dt/10;

  if(!f) {
    printf("Die!\n");
    exit(2);
  }

  xy[0] = c->x;
  xy[1] = c->y;

  for(i=0;i<10;i++) {
    interpolate_vel(vel, f, xy);
    if( (c->id % 500 == 0) && (i==0) ) {
      long x = c->x;
      long y = c->y;
      long of;
      of = ((x > 0) ? (x < f->w) ? x : f->w-1 : 0) +
	f->w * ((y > 0) ? (y < f->h) ? y : f->h-1 : 0);
      printf("cork %d: location %g,%g, vel %g,%g, (sample %g,%g), ddt %g, dx %g, displacement %g,%g pixels\n",c->id,xy[0],xy[1],vel[0],vel[1], f->V[of*2], f->V[of*2+1], ddt, dx, vel[0]*ddt/dx, vel[1]*ddt/dx);
    }
    xy[0] += vel[0] * ddt / dx ;  // div-by-dx converts scientific flow to pixel units
    xy[1] += vel[1] * ddt / dx;
  }
  
  c->x = xy[0];
  c->y = xy[1];

  return !( (c->x >= 1) &&
	   (c->x < f->w - 1) &&
	   (c->y >= 1) && 
	   (c->y < f->h - 1)
	   );
}


/**********************************************************************
 **********************************************************************
 ** div_flow - divergence flow calculator 
 ** given a divergence and an offset, return the flow velocity in the 
 ** given 2-vector and its magnitude directly.
 **
 ** The offsets should be given in world scientific units, not in pixels!
 ** The output is in scientific units.
 **/
double div_flow( double flow_out[2], double div, double x_of, double y_of ) {
  double dist2 = x_of*x_of + y_of * y_of;
  double dist;
  double magnitude;

  if(dist2 < 1e-4)
    dist2 = 1e-4;
  dist = sqrt(dist2);
  
  magnitude = div / ( dist2 * pi );

  flow_out[0] = x_of * magnitude / dist;
  flow_out[1] = y_of * magnitude / dist;
  return magnitude;
}

/**********************************************************************
 **********************************************************************
 *** granule/supergranule/cork updator/advector
 *** wld is the WORLD.
 *** c is the corks locations to update.  
 *** f is the corresponding flow field, or 0, due to the corks.
 *** fpre is the pre-existing flow field in which the corks should be advected, or 0
 *** ftot is the final flow field that should get the sum of the current and pre-existing fields, 
 ***   or 0 (should be 0 if f or fpre are 0).
 ***
 *** if the redux_flag is set then shrinkers are not deleted.
 */

void update_field(WORLD *wld, CORKS *corks, FIELD *f, FIELD *fpre, FIELD *ftot, char *name) {
  double dt = wld->p->dt;
  double t  = wld->t;
  long i, passno;
  long shrinkers;

  printf("Processing %ss...\n",name);
  printf("advecting %d %ss (maxn=%d)\n",corks->maxn - corks->unused, name, corks->maxn);

  if(fpre) {
    for(i=0;i<corks->maxn;i++) {
      if(corks->array[i].id) {
	if(advect_cork(corks->array + i, fpre, dt, wld->p->dx)) {
	  corks->array[i].id = 0;
	  corks->unused++;
	}
      }
    }
  }

  // If a field exists, then calculate and update the relevant portion of it.
  if(f) {
    passno = 0;
    do {
      shrinkers = 0;

      printf("updating %d %ss (maxn=%d); pass %d\n",corks->maxn - corks->unused, name, corks->maxn, passno);
      
      for(i=0;i<corks->maxn;i++) {
	if(corks->array[i].id) {
	  CORK *c = corks->array + i;
	  
	  double age, relage, rl, div;
	  long rmax_pix;
	  long xmin,xmax,ymin,ymax, x, y;	
	  double V[2];
	  long pix_count = 0; // number of field pixels affiliated with this cork
	  
	  age = (wld->t - c->t_born);
	  relage = age / corks->life;         // relative age
	  rl = (relage >0) ? ( (relage < 1) ? relage : 1) : 0; // clipped age
	  
	  
	  div = corks->div * (1 + 2 * sin( pi2 * rl )) / 2;    // calculated divergence

	  if(c->rmax_pix<=5)
	    c->rmax_pix=5;
 
	  rmax_pix = (  c->rmax_pix +                                                   // old rmax_pix
			div * wld->p->dt / wld->p->dx / wld->p->dx / c->rmax_pix        // divergence expansion
			+1
			) * 1.5;


	  //	  if(c->id % 500 == 0)
	  //	    printf("id %d: c->t_born=%g; t=%g; relage=%g; rl=%g; div=%g; c->rmax_pix=%d; rmax_pix = %d\n",c->id,c->t_born,wld->t,relage,rl,div,c->rmax_pix, rmax_pix );
	  
	  
	  // Now find the bounds of a small array that's rmax*2+1 x rmax*2+1 centered on the 
	  // granule location...
	  
	  xmin = c->x - rmax_pix;
	  if(xmin<0) xmin=0; if(xmin >= wld->p->w) xmin=wld->p->w-1;
	  
	  xmax = c->x + rmax_pix;
	  if(xmax<0) xmax=0; if(xmax >= wld->p->w) xmax=wld->p->w-1;
	  
	  ymin = c->y - rmax_pix;
	  if(ymin<0) ymin=0; if(ymin >= wld->p->h) ymax=wld->p->h-1;
	  
	  ymax = c->y + rmax_pix;
	  if(ymax<0) ymax=0; if(ymax >= wld->p->h) ymax=wld->p->h-1;
	  
	  // Iterate over the block...
	  rmax_pix = 0;

	  for(y=ymin; y<=ymax; y++) {
	    for(x=xmin; x<=xmax; x++) {
	      double flow_mag;
	      double existing_mag;
	      long of = y * f->w + x;
	      long of2 = of*2;
	      
	      flow_mag = div_flow( V, div, (x - c->x) * wld->p->dx, (y - c->y) * wld->p->dx );
	      
	      // If this pixel already belongs to this cork, or if the current calculated flow
	      // magnitude is greater than the existing flow magnitude, replace the pixel with 
	      // flow values from the current cork.
	      if( (f->id[of] == c->id) || 
		  ( (f->V[of2]*f->V[of2] + f->V[of2+1]*f->V[of2+1]) < flow_mag*flow_mag ) ) {
		double r2_pix;

		f->id[of] = c->id;
		f->V[of2]=V[0];
		f->V[of2+1]=V[1];
		pix_count++;

		r2_pix = (x - c->x) * (x - c->x) + (y - c->y) * (y - c->y);
		if(r2_pix > rmax_pix)
		  rmax_pix = r2_pix;

		if(ftot && fpre) {
		  ftot->V[of2]   = fpre->V[of2  ] + f->V[of2];
		  ftot->V[of2+1] = fpre->V[of2+1] + f->V[of2+1];
		}
	      }
	    }
	  }

	  c->rmax_pix = sqrt(rmax_pix);
	  
	  // Keep track of high-water pixel mark
	  if(pix_count > c->max_pixels)
	    c->max_pixels = pix_count;

	  // If the cork shrank too much, zero it out and delete it.
	  else if(pix_count < c->max_pixels / 4 || relage >= 1.5) {
	    //  printf(" cork %d is a shrinker - deleting...\n");
	    shrinkers++;
	    for(y=ymin; y<=ymax; y++) {
	      for(x=xmin; x<=xmax; x++) {
		long of = y * f->w + x;
		if(f->id[of] == c->id) {
		  f->id[of] = 0;
		  f->V[of*2] = f->V[of*2+1] = 0;
		}
	      }
	    }
	    //	    printf("  calling corks_delete_cork(%d) (id was %d;%d)\n",i,c->id,corks->array[i].id);
	    corks_delete_cork(corks, i); 
	  } // end of cork deletion
	} // end of cork-OK check
      } // end of corks loop
      if(shrinkers && (passno==0)) 
	printf("   found %d shrinkers; repeating\n",shrinkers);
    } while(shrinkers && (passno++)==0);
  } // end of field check
}
  


/**********************************************************************
 * update_sim - advance the simulation by <n> dt time steps
 */
void update_sim (WORLD *wld, long n_frames) {
  long i;
  for(i=0;i<n_frames;i++) {
    wld->t += wld->p->dt;
    printf( "t is %g; dt is %g\n",wld->t,wld->p->dt);

#if CORKS_DEBUG
    printf("psg..."); fflush(stdout);
#endif
    plonk_corks(wld, wld->sgc, new_supergranule);

#if CORKS_DEBUG
    printf("pg..."); fflush(stdout);
#endif
    plonk_corks(wld, wld->gc,  new_granule);

#if CORKS_DEBUG
    printf("sg..."); fflush(stdout);
#endif
    update_field(wld, wld->sgc, wld->sg, 0, 0, "supergranule");
#if CORKS_DEBUG
    printf("g..."); fflush(stdout);
#endif
    update_field(wld, wld->gc, wld->g, wld->sg, wld->tot, "granule");

#if CORKS_DEBUG
    printf("pmc...");; fflush(stdout);
#endif
    plonk_corks(wld, wld->mc, new_mag_bipole);

#if CORKS_DEBUG
    printf("mc..."); fflush(stdout);
#endif
    update_field(wld, wld->mc, 0, wld->tot, 0, "cork");
#if CORKS_DEBUG
    printf("\n");
#endif
  }
}


