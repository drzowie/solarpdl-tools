/**********************************************************************
 * Definitions for a corks model.
 */


/* FIELDs are variable-size and include a W x H (fast to slow) 
 * ID field and a 2 x W x H (fast to slow) velocity field.
 */

typedef struct FIELD {
  long fence;
  long w;
  long h;
  double *V;
  long *id;
} FIELD;

typedef struct CORK {
  long id;
  double x;
  double y;
  double t_born;
  long max_pixels;
  long rmax_pix;
} CORK;

typedef struct CORKS {
  long size;   /* size of allocated array */
  long maxn;   /* highest cork slot used  */
  long unused; /* number of unused slots  */
  CORK *array;
  // calculated parameters derived from global PARAMS field
  double life;       // lifetime of field corks (e.g. supergranules), seconds
  double corksize;   // typical size, in Mm
  double turnover;   // turnover rate, in turnovers per lifetime
  double div;        // calculated total expansion rate in scientific units...
  double plonkrate;  // how frequently they should randomly appear (corks per second)
  double plonktime;  // time at which last plonking happened
} CORKS;

typedef struct PARAMS {
  double dt;
  double dx;
  long w;
  long h;
  double g_life;
  double g_size;
  double g_turnover;
  double sg_life;
  double sg_size;
  double sg_turnover;
  double em_rate;
  double cork_size;
  double cork_B;
} PARAMS;


typedef struct WORLD {
  FIELD *sg;       /* supergranular flow field */
  FIELD *g;        /* granular flow field */
  FIELD *tot;      /* total flow field */
  CORKS *sgc;      /* supergranular corks */
  CORKS *gc;       /* granular corks */
  CORKS *mc;       /* magnetic corks */
  PARAMS *p;       /* global config parameters */
  long next_label;
  long next_clabel;
  double t;        /* elapsed time */
} WORLD;

  
PARAMS *new_params();
void free_params(PARAMS *p);
WORLD *new_world(long w, long h);
void free_world(WORLD *w);

void update_params(WORLD *w);

FIELD *new_field(long w, long h);
void free_field(FIELD *f);
void zero_field(FIELD *f);

void cork_cp(CORK *dest, CORK *src);
CORKS *new_corks(long initial_size);
void corks_grow(CORKS *cs, long target_size);
void corks_add_cork(CORKS *cs, CORK *c);

void corks_crunch_and_grow(CORKS *cs);
void corks_delete_cork(CORKS *cs, long pos);


/******************************/
/* cork/granule/supergranule addition & removal */
void new_mag_cork(WORLD *w, double x, double y, int negative);
void new_mag_bipole(WORLD *w, double x, double y, double deltat);

void new_granule(WORLD *w, double x, double y, double deltat);
void remove_granule(WORLD *w, long pos);

void new_supergranule(WORLD *w, double x, double y, double deltat);
void remove_supergranule(WORLD *w, long pos);

/******************************/
void plonk_mag_corks( WORLD *wld );
void plonk_granules( WORLD *wld );
void plonk_supergranules( WORLD *wld );
void plonk_corks( WORLD *wld, CORKS *corks, void (*plonker)(WORLD *wld, double x, double y, double deltat) );
int advect_cork( CORK *c, FIELD *field, double dt, double dx );

/******************************/
double div_flow( double flow_out[2], double div, double x_of, double y_of );
void update_field(WORLD *wld, CORKS *corks, FIELD *f, FIELD *fpre, FIELD *ftot, char *name);
void update_sim(WORLD *wld, long n_frames);

