#define QK_OUTSIDE   0
#define QK_VAL_1     1
#define QK_COMMENT   2
#define QK_PI        3
#define QK_BANG      4
#define QK_CDATA     5
#define QK_NAME_1    6
#define QK_NAME_X    7
#define QK_NAME_GAP  8
#define QK_ATT_SPACE 9
#define QK_ATT_NAME  10
#define QK_ATT_EQ1   11
#define QK_ATT_EQX   12
#define QK_ATT_QUOT  13
#define QK_ENAME_X   14
#define QK_ERROR     15
#define QK_VAL_X     16

#ifdef WIN32
#include<stdlib.h>
#endif

#ifndef NULL
  #define NULL 0x00
#endif

struct nodec {
  struct nodec *curchild;
  struct nodec *parent;
  struct nodec *next;
  struct nodec *firstchild;
  struct nodec *lastchild;
  struct attc  *firstatt;
  struct attc  *lastatt;
  int   numchildren;
  int   numatt;
  char  *name;
  int   namelen;
  char  *value;
  int   vallen;
  int   type;// cdata or normal
  int   numvals;
};

struct nodec *nodec_addchildr( struct nodec *self, char *newname, int newnamelen, char *newval, int newvallen, int newtype );
struct nodec *nodec_addchild( struct nodec *self, char *newname, int newnamelen );
struct attc *nodec_addattr  ( struct nodec *self, char *newname, int newnamelen, char *newval, int newvallen );
struct attc *nodec_addatt  ( struct nodec *self, char *newname, int newnamelen );

struct nodec *new_nodecp( struct nodec *newparent );
struct nodec *new_nodec();
void del_nodec( struct nodec *node );

struct attc {
  struct nodec *parent;
  struct attc  *next;
  char  *name;
  int   namelen;
  char  *value;
  int   vallen;
};

struct attc* new_attc( struct nodec *newparent );

struct parserc {
  struct nodec *pcurnode;
  struct attc  *curatt;
};

struct nodec* parserc_parse( struct parserc *self, char *newbuf );
