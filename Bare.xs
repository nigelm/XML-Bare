#define PERL_NO_GET_CONTEXT
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
    parserc_next_att(&parser);

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
    ST(0) = newSVpvn_share( parser.curatt->name, parser.curatt->namelen, 0 );
    XSRETURN(1);

char *
att_value()
  CODE:
    ST(0) = newSVpvn_share( parser.curatt->value, parser.curatt->vallen, 0 );
    XSRETURN(1);

char *
node_name()
  CODE:
    ST(0) = newSVpvn_share( parser.pcurnode->name, parser.pcurnode->namelen, 0 );
    XSRETURN(1);

char *
node_value()
  CODE:
    ST(0) = newSVpvn_share( parser.pcurnode->value, parser.pcurnode->vallen, 0 );
    XSRETURN(1);

void
free_tree()
  CODE:
    del_nodec( root );