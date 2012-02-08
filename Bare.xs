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

/* -------------------------------------------------------------------- */

/*
-- xml_dequote_string is a slightly adapted version of xml_dequote
-- from the XML::Quote package by Sergey Skvortsov
*/
static SV *xml_dequote_string(unsigned char *src, STRLEN src_len)
{
  SV *dstSV;
  unsigned char *src2;
  unsigned char *dst;
  unsigned char c, c1, c2, c3, c4;
  STRLEN src_len2, dst_len;

  src2 = src;
  src_len2 = src_len;
  dst_len = src_len;

  // calculate dequoted string length
  while (src_len >= 3) {
    c = *src++;
    src_len--;

    if ('&' != c) {
      continue;
    }

    /* We have "&", now look for:- &amp; &quot; &apos; &lt; &gt; */
    c = *src;
    c1 = *(src + 1);
    c2 = *(src + 2);
    if (c2 == ';' && c1 == 't' && (c == 'l' || c == 'g')) {
      dst_len -= 3;
      src += 3;
      src_len -= 3;
      continue;
    }

    if (src_len >= 4) {
      c3 = *(src + 3);
    } else {
      continue;
    }

    if (c == 'a' && c1 == 'm' && c2 == 'p' && c3 == ';') {
      dst_len -= 4;
      src += 4;
      src_len -= 4;
      continue;
    }

    if (src_len >= 5) {
      c4 = *(src + 4);
    } else {
      continue;
    }

    if (c4 == ';'
        && ((c == 'q' && c1 == 'u' && c2 == 'o' && c3 == 't') || (c == 'a' && c1 == 'p' && c2 == 'o' && c3 == 's'))) {
      dst_len -= 5;
      src += 5;
      src_len -= 5;
      continue;
    }                           //if
  }                             //while

  if (dst_len == src_len2) {
    // nothing to dequote
    dstSV = newSVpv(src2, dst_len);
    return dstSV;
  }

  /* We have someting to dequote, so make a SV to put it into */
  dstSV = newSV(dst_len);
  SvCUR_set(dstSV, dst_len);
  SvPOK_on(dstSV);
  dst = SvPVX(dstSV);

  while (src_len2 >= 3) {       // 3 is min length of quoted symbol
    c = *src2++;
    src_len2--;
    if ('&' != c) {
      *dst++ = c;
      continue;
    }
    c = *src2;
    c1 = *(src2 + 1);
    c2 = *(src2 + 2);

    // 1. test len=3: &lt; &gt;
    if (c1 == 't' && c2 == ';') {
      if (c == 'l') {
        *dst++ = '<';
        src2 += 3;
        src_len2 -= 3;
        continue;
      } else if (c == 'g') {
        *dst++ = '>';
      } else {
        *dst++ = '&';
        continue;
      }
      src2 += 3;
      src_len2 -= 3;
      continue;
    }                           //if lt | gt


    // 2. test len=4: &amp;
    if (src_len2 >= 4) {
      c3 = *(src2 + 3);
    } else {
      *dst++ = '&';
      continue;
    }

    if (c == 'a' && c1 == 'm' && c2 == 'p' && c3 == ';') {
      *dst++ = '&';
      src2 += 4;
      src_len2 -= 4;
      continue;
    }
    // 3. test len=5: &quot; &apos;
    if (src_len2 >= 5) {
      c4 = *(src2 + 4);
    } else {
      *dst++ = '&';
      continue;
    }

    if (c4 == ';') {
      if (c == 'q' && c1 == 'u' && c2 == 'o' && c3 == 't') {
        *dst++ = '"';
      } else if (c == 'a' && c1 == 'p' && c2 == 'o' && c3 == 's') {
        *dst++ = '\'';
      } else {
        *dst++ = '&';
        continue;
      }
      src2 += 5;
      src_len2 -= 5;
      continue;
    }                           //if ;

    *dst++ = '&';
  }                             //while


  while (src_len2-- > 0) {      // also copy trailing \0
    *dst++ = *src2++;
  }

  return dstSV;
}

/* -------------------------------------------------------------------- */

SV *node_val_unescaped(struct nodec * thisnode)
{
  SV *sv;

  if (curnode->type == NODE_TYPE_ESCAPED)
    sv = xml_dequote_string(curnode->value, curnode->vallen);
  else
    sv = newSVpvn(curnode->value, curnode->vallen);

  SvUTF8_on(sv);

  return sv;
}

/* -------------------------------------------------------------------- */

SV *cxml2obj()
{
  HV *output = newHV();
  SV *outputref = newRV_noinc((SV *) output);
  int i;
  struct attc *curatt;
  int numatts = curnode->numatt;
  SV *attval;
  SV *attatt;

  int length = curnode->numchildren;
  SV *svi = newSViv(curnode->pos);

  hv_store(output, "_pos", 4, svi, phash);
  hv_store(output, "_i", 2, newSViv(curnode->name - rootpos), ihash);
  hv_store(output, "_z", 2, newSViv(curnode->z), zhash);
  if (!length) {
    if (curnode->vallen) {
      SV *sv = node_val_unescaped(curnode);
      hv_store(output, "value", 5, sv, vhash);
      if (curnode->type & NODE_TYPE_CDATA) {
        SV *svi = newSViv(1);
        hv_store(output, "_cdata", 6, svi, cdhash);
      }
    }
    if (curnode->comlen) {
      SV *sv = newSVpvn(curnode->comment, curnode->comlen);
      SvUTF8_on(sv);
      hv_store(output, "comment", 7, sv, chash);
    }
  } else {
    if (curnode->vallen) {
      SV *sv = node_val_unescaped(curnode);
      hv_store(output, "value", 5, sv, vhash);
      if (curnode->type & NODE_TYPE_CDATA) {
        SV *svi = newSViv(1);
        hv_store(output, "_cdata", 6, svi, cdhash);
      }
    }
    if (curnode->comlen) {
      SV *sv = newSVpvn(curnode->comment, curnode->comlen);
      SvUTF8_on(sv);
      hv_store(output, "comment", 7, sv, chash);
    }

    curnode = curnode->firstchild;
    for (i = 0; i < length; i++) {
      SV *key = newSVpv(curnode->name, curnode->namelen);
      SvUTF8_on(key);
      HE *curh = hv_fetch_ent(output, key, 0, 0);

      if (curnode->namelen > 6) {
        if (!strncmp(curnode->name, "multi_", 6)) {
          SV *subkey = newSVpv(&curnode->name[6], curnode->namelen - 6);
          SvUTF8_on(subkey);
          HE *oldh = hv_fetch_ent(output, subkey, 0, 0);
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc((SV *) newarray);
          if (!oldh) {
            hv_store_ent(output, subkey, newarrayref, 0);
          } else {
            SV *old = HeVAL(oldh);
            if (SvTYPE(SvRV(old)) == SVt_PVHV) {        // check for hash ref
              SV *newref = newRV((SV *) SvRV(old));
              hv_delete_ent(output, subkey, 0, 0);
              hv_store_ent(output, subkey, newarrayref, 0);
              av_push(newarray, newref);
            }
          }
          SvREFCNT_dec(subkey); // no longer need the subkey
        }
      }

      if (!curh) {
        hv_store_ent(output, key, cxml2obj(), 0);
      } else {
        SV *cur = HeVAL(curh);
        if (SvTYPE(SvRV(cur)) == SVt_PVHV) {
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc((SV *) newarray);
          SV *newref = newRV((SV *) SvRV(cur));
          hv_delete_ent(output, key, 0, 0);
          hv_store_ent(output, key, newarrayref, 0);
          av_push(newarray, newref);
          av_push(newarray, cxml2obj());
        } else {
          AV *av = (AV *) SvRV(cur);
          av_push(av, cxml2obj());
        }
      }
      if (i != (length - 1))
        curnode = curnode->next;
      SvREFCNT_dec(key);        // no longer need the key
    }

    curnode = curnode->parent;
  }

  if (numatts) {
    curatt = curnode->firstatt;
    for (i = 0; i < numatts; i++) {
      HV *atth = newHV();
      SV *atthref = newRV_noinc((SV *) atth);
      hv_store(output, curatt->name, curatt->namelen, atthref, 0);

      attval = newSVpvn(curatt->value, curatt->vallen);
      SvUTF8_on(attval);
      hv_store(atth, "value", 5, attval, vhash);
      attatt = newSViv(1);
      hv_store(atth, "_att", 4, attatt, ahash);
      if (i != (numatts - 1))
        curatt = curatt->next;
    }
  }
  return outputref;
}

/* -------------------------------------------------------------------- */

SV *cxml2obj_simple()
{
  int i;
  struct attc *curatt;
  int numatts = curnode->numatt;
  SV *attval;
  SV *attatt;
  HV *output;
  SV *outputref;

  int length = curnode->numchildren;
  if ((length + numatts) == 0) {
    if (curnode->vallen)
      return node_val_unescaped(curnode);
    else
      return newSVpv("", 0);    // an empty tag has empty string content
  }

  output = newHV();
  outputref = newRV_noinc((SV *) output);

  if (length) {
    curnode = curnode->firstchild;
    for (i = 0; i < length; i++) {
      SV *key = newSVpv(curnode->name, curnode->namelen);
      SvUTF8_on(key);
      HE *curh = hv_fetch_ent(output, key, 0, 0);

      if (curnode->namelen > 6) {
        if (!strncmp(curnode->name, "multi_", 6)) {
          SV *subkey = newSVpv(&curnode->name[6], curnode->namelen - 6);
          SvUTF8_on(subkey);
          HE *oldh = hv_fetch_ent(output, subkey, 0, 0);
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc((SV *) newarray);
          if (!oldh) {
            hv_store_ent(output, subkey, newarrayref, 0);
          } else {
            SV *old = HeVAL(oldh);
            if (SvTYPE(SvRV(old)) == SVt_PVHV) {        // check for hash ref
              SV *newref = newRV((SV *) SvRV(old));
              hv_delete_ent(output, subkey, 0, 0);
              hv_store_ent(output, subkey, newarrayref, 0);
              av_push(newarray, newref);
            }
          }
          SvREFCNT_dec(subkey); // no longer need the subkey
        }
      }

      if (!curh) {
        hv_store_ent(output, key, cxml2obj_simple(), 0);
      } else {
        SV *cur = HeVAL(curh);
        if (SvROK(cur)) {
          if (SvTYPE(SvRV(cur)) == SVt_PVHV) {
            AV *newarray = newAV();
            SV *newarrayref = newRV_noinc((SV *) newarray);
            SV *newref = newRV((SV *) SvRV(cur));
            hv_delete_ent(output, key, 0, 0);
            hv_store_ent(output, key, newarrayref, 0);
            av_push(newarray, newref);
            av_push(newarray, cxml2obj_simple());
          } else {
            AV *av = (AV *) SvRV(cur);
            av_push(av, cxml2obj_simple());
          }
        } else {
          AV *newarray = newAV();
          SV *newarrayref = newRV_noinc((SV *) newarray);

          STRLEN len;
          char *ptr = SvPV(cur, len);
          SV *newsv = newSVpvn(ptr, len);
          SvUTF8_on(newsv);

          av_push(newarray, newsv);
          hv_delete_ent(output, key, 0, 0);
          hv_store_ent(output, key, newarrayref, 0);
          av_push(newarray, cxml2obj_simple());
        }
      }
      if (i != (length - 1))
        curnode = curnode->next;
      SvREFCNT_dec(key);        // no longer need the key
    }
    curnode = curnode->parent;
  } else {
    SV *sv = node_val_unescaped(curnode);
    hv_store(output, "content", 7, sv, vhash);
  }

  if (numatts) {
    curatt = curnode->firstatt;
    for (i = 0; i < numatts; i++) {
      attval = newSVpvn(curatt->value, curatt->vallen);
      SvUTF8_on(attval);
      hv_store(output, curatt->name, curatt->namelen, attval, 0);
      if (i != (numatts - 1))
        curatt = curatt->next;
    }
  }

  return outputref;
}

/* -------------------------------------------------------------------- */

// *INDENT-OFF*
// Indent and XS declarations do not mix well :-(

MODULE = XML::Bare         PACKAGE = XML::Bare

SV *
xml2obj()
  CODE:
    if( root->err ) RETVAL = newSViv( root->err );
    else {
      curnode = root;
      RETVAL = cxml2obj();
    }
  OUTPUT:
    RETVAL
    
SV *
xml2obj_simple()
  CODE:
    PERL_HASH(vhash, "content", 7);
    curnode = root;
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
    root = parserc_parse( text );

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
    root = parserc_parse( data );
    free( data );

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
