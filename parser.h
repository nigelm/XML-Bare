#ifdef WIN32
#include<stdlib.h>
#endif

#ifndef NULL
#define NULL 0x00
#endif

#define NODE_TYPE_CDATA    1
#define NODE_TYPE_ESCAPED  2

struct nodec {
  struct nodec *curchild;
  struct nodec *parent;
  struct nodec *next;
  struct nodec *firstchild;
  struct nodec *lastchild;
  struct attc *firstatt;
  struct attc *lastatt;
  int numchildren;
  int numatt;
  char *name;
  int namelen;
  char *value;
  char *comment;
  int vallen;
  int comlen;
  int type;                     // cdata, normal or possibly escaped - see defines
  int numvals;
  int numcoms;
  int pos;
  int err;
  int z;
};

struct nodec *nodec_addchildr(struct nodec *self, char *newname, int newnamelen);       //, char *newval, int newvallen, int newtype );
//struct nodec *nodec_addchild( struct nodec *self, char *newname, int newnamelen );
struct attc *nodec_addattr(struct nodec *self, char *newname, int newnamelen);  //, char *newval, int newvallen );
//struct attc *nodec_addatt  ( struct nodec *self, char *newname, int newnamelen );

struct nodec *new_nodecp(struct nodec *newparent);
struct nodec *new_nodec();
void del_nodec(struct nodec *node);

struct attc {
  struct nodec *parent;
  struct attc *next;
  char *name;
  int namelen;
  char *value;
  int vallen;
};

struct attc *new_attc(struct nodec *newparent);

struct nodec *parserc_parse(char *newbuf);
