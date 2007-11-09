#include "EXTERN.h"
#define PERL_IN_HV_C
#define PERL_HASH_INTERNAL_ACCESS
#include "perl.h"
#include "XSUB.h"
#include "parser.h"
#include "stdio.h"
#include "string.h"

#ifndef newSVpvn			/* 5.005_62 or so */
  #define newSVpvn newSVpv
#endif
#ifndef aTHX_         /* 5.005 */
#  define aTHX_
#endif
#ifndef pTHX_         /* 5.005 */
#  define pTHX_
#endif

struct parserc parser;
struct nodec *root;

U32 vhash;
U32 chash;

struct nodec *curnode;
  

SV *cxml2obj(pTHX_ int a) {
  HV *output = newHV();
  SV *outputref = newRV( (SV *) output );
  
  int length = curnode->numchildren;
  if( !length ) {
    if( curnode->vallen ) {
      SV * sv = newSVpvn( curnode->value, curnode->vallen );
      hv_store( output, "value", 5, sv, vhash );
    }
    if( curnode->comlen ) {
      SV * sv = newSVpvn( curnode->comment, curnode->comlen );
      hv_store( output, "comment", 7, sv, chash );
    }
  }
  else {
    if( curnode->vallen ) {
      SV *sv = newSVpvn( curnode->value, curnode->vallen );
      hv_store( output, "value", 5, sv, vhash );
    }
    if( curnode->comlen ) {
      SV *sv = newSVpvn( curnode->comment, curnode->comlen );
      hv_store( output, "comment", 7, sv, chash );
    }
    
    curnode = curnode->firstchild;
    int i;
    for( i = 0; i < length; i++ ) {
      SV *namesv = newSVpvn( curnode->name, curnode->namelen );
      
      SV **cur = hv_fetch( output, curnode->name, curnode->namelen, 0 );
      
      if( curnode->namelen > 6 ) {
        if( !strncmp( curnode->name, "multi_", 6 ) ) {
          char *subname = &curnode->name[6];
          int subnamelen = curnode->namelen-6;
          SV **old = hv_fetch( output, subname, subnamelen, 0 );
          AV *newarray = newAV();
          SV *newarrayref = newRV( (SV *) newarray );
          if( !old ) {
            hv_store( output, subname, subnamelen, newarrayref, 0 );
          }
          else {
            if( SvTYPE( SvRV(*old) ) == SVt_PVHV ) { // check for hash ref
              SV *newref = newRV( (SV *) SvRV(*old) );
              hv_delete( output, subname, subnamelen, 0 );
              hv_store( output, subname, subnamelen, newarrayref, 0 );
              av_push( newarray, newref );
            }
          }
        }
      }
        
      if( !cur ) {
        SV *ob = cxml2obj( aTHX_ 0 );
        hv_store( output, curnode->name, curnode->namelen, ob, 0 );
      }
      else {
        if( SvTYPE( SvRV(*cur) ) == SVt_PVHV ) {
          AV *newarray = newAV();
          SV *newarrayref = newRV( (SV *) newarray );
          SV *newref = newRV( (SV *) SvRV( *cur ) );
          hv_delete( output, curnode->name, curnode->namelen, 0 );
          hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
          av_push( newarray, newref );
          av_push( newarray, cxml2obj( aTHX_ 0 ) );
        }
        else {
          AV *av = (AV *) SvRV( *cur );
          av_push( av, cxml2obj( aTHX_ 0) );
        }
      }
      if( i != ( length - 1 ) ) curnode = curnode->next;
    }
    
    curnode = curnode->parent;
  }
  
  struct attc *curatt;
  int numatts = curnode->numatt;
  if( numatts ) {
    curatt = curnode->firstatt;
    int i;
    for( i = 0; i < numatts; i++ ) {
      HV *atth = newHV();
      SV *atthref = newRV( (SV *) atth );
      hv_store( output, curatt->name, curatt->namelen, atthref, 0 );
      
      SV *attval = newSVpvn( curatt->value, curatt->vallen );
      hv_store( atth, "value", 5, attval, vhash );
      SV *attatt = newSViv( 1 );
      hv_store( atth, "att", 3, attatt, 0 );
      if( i != ( numatts - 1 ) ) curatt = curatt->next;
    }
  }
  return outputref;
}

MODULE = XML::Bare         PACKAGE = XML::Bare

SV *
xml2obj()
  CODE:
    curnode = parser.pcurnode;
    RETVAL = cxml2obj(aTHX_ 0);
  OUTPUT:
    RETVAL
    
void
c_parse(text)
  char * text
  CODE:
    PERL_HASH(vhash, "value", 5);
    PERL_HASH(chash, "comment", 7);
    int len = strlen( text );
    parserc_parse( &parser, text, len );
    root = parser.pcurnode;
    
void
c_parsefile(filename)
  char * filename
  CODE:
    char *data;
    unsigned long len;
    FILE *handle;
    handle = fopen(filename,"r");
    
    fseek( handle, 0, SEEK_END );
    
    len = ftell( handle );
    
    fseek( handle, 0, SEEK_SET );
    data = (char *) malloc( len );
    fread( data, 1, len, handle );
    fclose( handle );
    parserc_parse( &parser, data, len );
    root = parser.pcurnode;

void
free_tree()
  CODE:
    del_nodec( root );