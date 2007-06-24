#define PERL_NO_GET_CONTEXT
#define MY_BLIND_PV(a,b) SV *sv;sv=newSV(0);SvUPGRADE(sv,SVt_PV);SvPV_set(sv,a);SvCUR_set(sv,b);SvLEN_set(sv, b+1);SvPOK_only_UTF8(sv);ST(0) = sv;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "parser.h"

struct parserc parser;
struct nodec *root;

MODULE = XML::Bare         PACKAGE = XML::Bare

void
c_parse(text)
  char * text
  CODE:
    parserc_parse( &parser, text );
    root = parser.pcurnode;
    
void
descend()
  CODE:
    parser.pcurnode = parser.pcurnode->firstchild;
    
void
ascend()
  CODE:
    parser.pcurnode = parser.pcurnode->parent;
    
void
next_node()
  CODE:
    parser.pcurnode = parser.pcurnode->next;
    
void
first_att()
  CODE:
    parser.curatt   = parser.pcurnode->firstatt;
    
void
next_att()
  CODE:
    parser.curatt = parser.curatt->next;

int
num_att()
  CODE:
    RETVAL = parser.pcurnode->numatt; 
  OUTPUT:
    RETVAL

int
node_type()
  CODE:
    RETVAL = parser.pcurnode->type;
  OUTPUT:
    RETVAL

int
num_nodes()
  CODE:
    RETVAL = parser.pcurnode->numchildren;
  OUTPUT:
    RETVAL

char *
att_name()
  CODE:
    MY_BLIND_PV( parser.curatt->name, parser.curatt->namelen )
    XSRETURN(1);

char *
att_value()
  CODE:
    MY_BLIND_PV( parser.curatt->value, parser.curatt->vallen )
    XSRETURN(1);

char *
node_name()
  CODE:
    MY_BLIND_PV( parser.pcurnode->name, parser.pcurnode->namelen )
    XSRETURN(1);

char *
node_value()
  CODE:
    MY_BLIND_PV( parser.pcurnode->value, parser.pcurnode->vallen )
    XSRETURN(1);

void
free_tree()
  CODE:
    del_nodec( root );