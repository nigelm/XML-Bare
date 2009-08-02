// JEdit mode Line -> :folding=indent:mode=c++:indentSize=2:noTabs=true:tabSize=2:
#include "EXTERN.h"
#define PERL_IN_HV_C
#define PERL_HASH_INTERNAL_ACCESS

#include "perl.h"
#include "XSUB.h"
#include "parser.h"

struct nodec *root;

U32 vhash;
U32 chash;
U32 phash;
U32 ihash;
U32 cdhash;
U32 zhash;
U32 ahash;

struct nodec *curnode;
char *rootpos;
  
SV *cxml2obj() {
  HV *output = newHV();
  SV *outputref = newRV_noinc( (SV *) output );
  int i;
  struct attc *curatt;
  int numatts = curnode->numatt;
  SV *attval;
  SV *attatt;
      
  int length = curnode->numchildren;
  SV *svi = newSViv( curnode->pos );
  
  hv_store( output, "_pos", 4, svi, phash );
  hv_store( output, "_i", 2, newSViv( curnode->name - rootpos ), ihash );
  hv_store( output, "_z", 2, newSViv( curnode->z ), zhash );
  if( !length ) {
    if( curnode->vallen ) {
      SV * sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      hv_store( output, "value", 5, sv, vhash );
      if( curnode->type ) {
        SV *svi = newSViv( 1 );
        hv_store( output, "_cdata", 6, svi, cdhash );
      }
    }
    if( curnode->comlen ) {
      SV * sv = newSVpvn( curnode->comment, curnode->comlen );
      SvUTF8_on(sv);
      hv_store( output, "comment", 7, sv, chash );
    }
  }
  else {
    if( curnode->vallen ) {
      SV *sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      hv_store( output, "value", 5, sv, vhash );
      if( curnode->type ) {
        SV *svi = newSViv( 1 );
        hv_store( output, "_cdata", 6, svi, cdhash );
      }
    }
    if( curnode->comlen ) {
      SV *sv = newSVpvn( curnode->comment, curnode->comlen );
      SvUTF8_on(sv);
      hv_store( output, "comment", 7, sv, chash );
    }
    
    curnode = curnode->firstchild;
    for( i = 0; i < length; i++ ) {
      SV **cur = hv_fetch( output, curnode->name, curnode->namelen, 0 );
      
      if( curnode->namelen > 6 ) {
        if( !strncmp( curnode->name, "multi_", 6 ) ) {
          char *subname = &curnode->name[6];
          int subnamelen = curnode->namelen-6;
          SV **old = hv_fetch( output, subname, subnamelen, 0 );
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc( (SV *) newarray );
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
        SV *ob = cxml2obj();
        hv_store( output, curnode->name, curnode->namelen, ob, 0 );
      }
      else {
        if( SvTYPE( SvRV(*cur) ) == SVt_PVHV ) {
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc( (SV *) newarray );
          SV *newref = newRV( (SV *) SvRV( *cur ) );
          SV *ob;
          hv_delete( output, curnode->name, curnode->namelen, 0 );
          hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
          av_push( newarray, newref );
          ob = cxml2obj();
          av_push( newarray, ob );
        }
        else {
          AV *av = (AV *) SvRV( *cur );
          SV *ob = cxml2obj();
          av_push( av, ob );
        }
      }
      if( i != ( length - 1 ) ) curnode = curnode->next;
    }
    
    curnode = curnode->parent;
  }
  
  if( numatts ) {
    curatt = curnode->firstatt;
    for( i = 0; i < numatts; i++ ) {
      HV *atth = newHV();
      SV *atthref = newRV_noinc( (SV *) atth );
      hv_store( output, curatt->name, curatt->namelen, atthref, 0 );
      
      attval = newSVpvn( curatt->value, curatt->vallen );
      SvUTF8_on(attval);
      hv_store( atth, "value", 5, attval, vhash );
      attatt = newSViv( 1 );
      hv_store( atth, "_att", 4, attatt, ahash );
      if( i != ( numatts - 1 ) ) curatt = curatt->next;
    }
  }
  return outputref;
}

SV *cxml2obj_simple() {
  int i;
  struct attc *curatt;
  int numatts = curnode->numatt;
  SV *attval;
  SV *attatt;
  HV *output;
  SV *outputref;
  
  int length = curnode->numchildren;
  if( ( length + numatts ) == 0 ) {
    if( curnode->vallen ) {
      SV * sv = newSVpvn( curnode->value, curnode->vallen );
      SvUTF8_on(sv);
      return sv;
    }
    return newSViv( 1 ); //&PL_sv_undef;
  }
  
  output = newHV();
  outputref = newRV( (SV *) output );
  
  if( length ) {
    curnode = curnode->firstchild;
    for( i = 0; i < length; i++ ) {
      SV *namesv = newSVpvn( curnode->name, curnode->namelen );
      SvUTF8_on(namesv);
      
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
        SV *ob = cxml2obj_simple();
        hv_store( output, curnode->name, curnode->namelen, ob, 0 );
      }
      else {
        if( SvROK( *cur ) ) {
          if( SvTYPE( SvRV(*cur) ) == SVt_PVHV ) {
            AV *newarray = newAV();
            SV *newarrayref = newRV( (SV *) newarray );
            SV *newref = newRV( (SV *) SvRV( *cur ) );
            hv_delete( output, curnode->name, curnode->namelen, 0 );
            hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
            av_push( newarray, newref );
            av_push( newarray, cxml2obj_simple() );
          }
          else {
            AV *av = (AV *) SvRV( *cur );
            av_push( av, cxml2obj_simple() );
          }
        }
        else {
          AV *newarray = newAV();
          SV *newarrayref = newRV( (SV *) newarray );
          
          STRLEN len;
          char *ptr = SvPV(*cur, len);
          SV *newsv = newSVpvn( ptr, len );
          SvUTF8_on(newsv);
          
          av_push( newarray, newsv );
          hv_delete( output, curnode->name, curnode->namelen, 0 );
          hv_store( output, curnode->name, curnode->namelen, newarrayref, 0 );
          av_push( newarray, cxml2obj_simple() );
        }
      }
      if( i != ( length - 1 ) ) curnode = curnode->next;
    }
    curnode = curnode->parent;
  }
  
  if( numatts ) {
    curatt = curnode->firstatt;
    for( i = 0; i < numatts; i++ ) {
      attval = newSVpvn( curatt->value, curatt->vallen );
      SvUTF8_on(attval);
      hv_store( output, curatt->name, curatt->namelen, attval, 0 );
      if( i != ( numatts - 1 ) ) curatt = curatt->next;
    }
  }
  
  return outputref;
}

struct parserc *parser = 0;

MODULE = XML::Bare         PACKAGE = XML::Bare

SV *
xml2obj()
  CODE:
    curnode = parser->pcurnode;
    if( curnode->err ) RETVAL = newSViv( curnode->err );
    else RETVAL = cxml2obj();
  OUTPUT:
    RETVAL
    
SV *
xml2obj_simple()
  CODE:
    curnode = parser->pcurnode;
    RETVAL = cxml2obj_simple();
  OUTPUT:
    RETVAL

void
c_parse(text)
  char * text
  CODE:
    rootpos = text;
    PERL_HASH(vhash, "value", 5);
    PERL_HASH(ahash, "_att", 4);
    PERL_HASH(chash, "comment", 7);
    PERL_HASH(phash, "_pos", 4);
    PERL_HASH(ihash, "_i", 2 );
    PERL_HASH(zhash, "_z", 2 );
    PERL_HASH(cdhash, "_cdata", 6 );
    parser = (struct parserc *) malloc( sizeof( struct parserc ) );
    root = parserc_parse( parser, text );
    
void
c_parsefile(filename)
  char * filename
  CODE:
    char *data;
    unsigned long len;
    FILE *handle;
    
    PERL_HASH(vhash, "value", 5);
    PERL_HASH(ahash, "_att", 4);
    PERL_HASH(chash, "comment", 7);
    PERL_HASH(phash, "_pos", 4);
    PERL_HASH(ihash, "_i", 2 );
    PERL_HASH(zhash, "_z", 2 );
    PERL_HASH(cdhash, "_cdata", 6 );
    
    handle = fopen(filename,"r");
    
    fseek( handle, 0, SEEK_END );
    
    len = ftell( handle );
    
    fseek( handle, 0, SEEK_SET );
    data = (char *) malloc( len );
    rootpos = data;
    fread( data, 1, len, handle );
    fclose( handle );
    parser = (struct parserc *) malloc( sizeof( struct parserc ) );
    root = parserc_parse( parser, data );

SV *
get_root()
  CODE:
    RETVAL = newSVuv( PTR2UV( root ) );
  OUTPUT:
    RETVAL

void
free_tree_c( rootsv )
  SV *rootsv
  CODE:
    struct nodec *rootnode;
    rootnode = INT2PTR( struct nodec *, SvUV( rootsv ) );
    del_nodec( rootnode );