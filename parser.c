#include "parser.h"

struct nodec *nodec_addchild( struct nodec *self, char *newname, int newnamelen ) {
  return nodec_addchildr( self, newname,newnamelen,0,0,0);
};
struct attc *nodec_addatt  ( struct nodec *self, char *newname, int newnamelen ) {
  return nodec_addattr( self, newname, newnamelen, 0, 0 );
};

struct nodec *new_nodecp( struct nodec *newparent ) {
  struct nodec *self = (struct nodec *) malloc( sizeof( struct nodec ) );
  self->next        = NULL;
  self->parent      = newparent;
  self->firstchild  = NULL;
  self->lastchild   = NULL;
  self->numchildren = 0;
  self->numatt      = 0;
  self->namelen     = 0;
  self->vallen      = 0;
  self->numvals     = 0;
  return self;
}

struct nodec *new_nodec() {
  struct nodec *self = (struct nodec *) malloc( sizeof( struct nodec ) );
  self->next        = NULL;
  self->parent      = NULL;
  self->firstchild  = NULL;
  self->lastchild   = NULL;
  self->numchildren = 0;
  self->numatt      = 0;
  self->name        = 0x00;
  self->value       = 0x00;
  self->namelen     = 0;
  self->vallen      = 0;
  return self;
}

void del_nodec( struct nodec *node ) {
  struct nodec *curnode;
  struct attc *curatt;
  struct nodec *next;
  struct attc *nexta;
  if( node->numchildren ) {
    curnode = node->firstchild;
    while( 1 ) {
      next = curnode->next;
      del_nodec( curnode );
      curnode = next;
      if( !curnode ) break;
    }
  }
  if( node->numatt ) {
    curatt = node->firstatt;
    while( 1 ) {
      nexta = curatt->next;
      free( curatt );
      curatt = nexta;
      if( !curatt ) break;
    }
  }
  free( node );
}

struct attc* new_attc( struct nodec *newparent ) {
  struct attc *self = (struct attc *) malloc( sizeof( struct attc ) );
  self->next    = NULL;
  self->parent  = newparent;
  self->namelen = 0;
  self->vallen  = 0;
  self->name    = 0x00;
  self->value   = 0x00;
  return self;
}

struct nodec* parserc_parse( struct parserc *self, char *xmlin ) {
    struct nodec *root = new_nodec();

    char  *tagname, *attname, *attval, *val;
    int   pos         = 0;
    int   state       = QK_VAL_1;
    int   tagname_len = 0;
    int   attname_len = 0;
    int   attval_len  = 0;
    struct nodec *curnode    = root;
    struct attc  *curatt     = NULL;
    char  let;
    
    while( 1 ) {
        if( curnode == 0x00 ) break;
        
        // itty bit faster without the following
        // protect from garbage being fed to processor
        //if( tagname_len > 38   ) break;
        //if( attname_len > 38   ) break;
        //if( attval_len  > 148  ) break;
        
        let = xmlin[ pos ];
        if( !let ) break;

        switch( state ) {

            case QK_OUTSIDE: // outside, waiting for <
                if( let == '<' ) {
                    state       = QK_NAME_1;
                    tagname_len = 0; // for safety
                }
                break;
            
            case QK_VAL_1:
            case QK_VAL_X: // outside grabbing value
                if( let == '<' ) {
                    if( xmlin[ pos + 1 ] == '!') {
                        if( xmlin[ pos + 2 ] == '[' ) { // <![
                            if( xmlin[ pos + 3 ] == 'C' &&
                                xmlin[ pos + 4 ] == 'D' &&
                                xmlin[ pos + 5 ] == 'A' &&
                                xmlin[ pos + 6 ] == 'T' &&
                                xmlin[ pos + 7 ] == 'A'    ) {
                                    pos += 8;
                                    state = QK_CDATA;
                                    break;
                            }
                            else {
                                state = QK_ERROR; // unrecognized <![ section
                                break;
                            }
                        }
                        else if( xmlin[ pos + 2 ] == '-' && // <!--
                            xmlin[ pos + 3 ] == '-' ) {
                                pos += 3;
                                state = QK_COMMENT;
                                break;
                            }
                        else {
                            state = QK_BANG; // unrecognized <! section
                            break;
                        }
                    }
                    else if( xmlin[ pos + 1 ] == '?' ) { // <?
                        pos++;
                        state = QK_PI;
                        break;
                    }
                    else { 
                        state           = QK_NAME_1;
                        tagname_len     = 0; // for safety
                        break;
                    }
                }
                if( state == QK_VAL_1 ) {
                  if( !curnode->numvals ) {
                    curnode->value = &xmlin[ pos ];
                    curnode->vallen = 1;
                  }
                  curnode->numvals++;
                  state = QK_VAL_X;
                }
                else {
                  if( curnode->numvals == 1 ) {
                    curnode->vallen++;
                  }
                }
                break;

            case QK_COMMENT:
                if( let == '-' &&
                    xmlin[ pos + 1 ] == '-' &&
                    xmlin[ pos + 2 ] == '>' ) {
                        state = QK_VAL_1;
                        pos += 2;
                        break;
                    }
                break;

            case QK_PI:
                if( let == '?' &&
                    xmlin[ pos + 1 ] == '>' ) {
                        state = QK_VAL_1;
                        pos ++;
                    }
                break;

            case QK_BANG:
                if( let == '>' ) {
                  state = QK_VAL_1;
                }
                break;

            case QK_CDATA: // cdata section
                if( let == ']' &&
                    xmlin[ pos + 1 ] == ']' &&
                    xmlin[ pos + 2 ] == '>' ) {
                        state = QK_VAL_1;
                        pos += 2;
                        break;
                }
                if( !curnode->numvals ) {
                  curnode->value = &xmlin[ pos ];
                  curnode->vallen = 0;
                  curnode->numvals = 1;
                }
                if( curnode->numvals == 1 ) curnode->vallen++;
                
                break;

            case QK_NAME_1: // grabbing first letter after <
                if( let == ' ' || let == 0x0d || let == 0x0a ) break;
                if( let == '/' ) {
                    state       = QK_ENAME_X;
                    tagname_len = 0; // needed to reset
                    break;
                }
                tagname       = &xmlin[ pos ];
                tagname_len   = 1;
                state         = QK_NAME_X;
                break;

            case QK_NAME_X: // grabbing tag name
                if( let == ' ' || let == 0x0d || let == 0x0a ) {
                    curnode                = nodec_addchild( curnode, tagname, tagname_len );
                    state                  = QK_NAME_GAP;
                    attname_len            = 0;
                }
                else if( let == '>' ) {
                    curnode                = nodec_addchild( curnode, tagname, tagname_len );
                    state                  = QK_VAL_1;
                }
                else if( let == '/' ) {
                    state                  = QK_VAL_1;
                    nodec_addchild( curnode, tagname, tagname_len );
                    tagname_len            = 0;
                    pos++;
                }
                else {
                    tagname_len++;
                }
                break;

            case QK_NAME_GAP: // space after tag name was found
                if( let == ' ' || let == 0x0d || let == 0x0a ) break;
                if( let == '>' ) {
                    state = QK_VAL_1;
                    break;
                }
                if( let == '/' ) {
                    state = QK_VAL_1;
                    curnode = curnode->parent;
                    pos++; // am assuming next char is >
                    break;
                }
                if( let == '=' ) {
                    state = QK_ERROR; // error state
                    break;
                }
                
                state   = QK_ATT_NAME;
                attname = &xmlin[ pos ];
                attname_len = 1; // this really is needed... don't remove it
                
                break;

            case QK_ATT_SPACE:
                // we already grabbed the att name, now either go to name gap or att eq
                if( let == ' ' || let == 0x0d || let == 0x0a ) break;
                if( let == '=' ) {
                    state = QK_ATT_EQ1;
                    break;
                }
                // we have another attribute name, so continue
            
            case QK_ATT_NAME: // grabbing attribute name
                if( let == '/' ) {
                    state = QK_VAL_1;
                    curnode = curnode->parent;
                    pos++;
                }
                else if( let == ' ' && xmlin[ pos + 1 ] == '=' ) {
                    break;
                }
                else if( let == ' ' ) state = QK_ATT_SPACE;
                else if( let == '>' ) state = QK_VAL_1;
                else if( let == '=' ) {
                    state      = QK_ATT_EQ1;
                    attval_len = 0;
                }
                else {
                    if( !attname_len ) attname = &xmlin[pos];
                    attname_len++;
                    break;
                }
                curatt = nodec_addatt( curnode, attname, attname_len );
                attname_len            = 0;
                break;

            case QK_ATT_EQ1: // grabbing attribute value (after eq)
                if( let == '/' && xmlin[ pos + 1 ] == '>' ) {
                    state = QK_VAL_1;
                    curnode = curnode->parent;
                    pos++;
                }
                else if( let == '"' ) state = QK_ATT_QUOT;
                else if( let == '>' ) state = QK_VAL_1;
                else if( let == ' ' ) break; //state = QK_NAME_GAP;
                else {
                    if( !attval_len ) attval = &xmlin[ pos ];
                    attval_len++;
                    state = QK_ATT_EQX;
                }
                break;

            case QK_ATT_EQX:
                if( let == '/' && xmlin[ pos + 1 ] == '>' ) {
                    state = QK_VAL_1;
                    curnode = curnode->parent;
                    pos++;
                }
                else if( let == '>' ) state = QK_VAL_1;
                else if( let == ' ' ) state = QK_NAME_GAP;
                else {
                    if( !attval_len ) attval = &xmlin[ pos ];
                    attval_len++;
                    break;
                }
                
                curatt->value = attval;
                curatt->vallen = attval_len;
                attval_len    = 0;
                break;
            
            case QK_ATT_QUOT:
                if( let == '"' ) state = QK_NAME_GAP;
                else {
                    if( !attval_len ) attval = &xmlin[ pos ];
                    attval_len++;
                    break;
                }
                
                if( attval_len ) {
                    curatt->value = attval;
                    
                }
                curatt->vallen = attval_len;
                
                attval_len           = 0;
                break;

            case QK_ENAME_X: // grabbing close tag name
                if( let == '>' ) {
                    state = QK_VAL_1;
                    curnode->namelen = tagname_len;
                    curnode = curnode->parent;
                }
                tagname_len++;
                break;
            case QK_ERROR:
                // if we ever get here it is a bad thing
                break;
        }
        pos++;
    }
    self->pcurnode = root;
    self->pcurnode->curchild = self->pcurnode->firstchild;
    return root;
}

struct nodec *nodec_addchildr(  struct nodec *self, char *newname, int newnamelen, char *newval, int newvallen, int newtype ) {
  struct nodec *newnode = new_nodecp( self );
  newnode->name    = newname;
  newnode->namelen = newnamelen;
  newnode->value   = newval;
  newnode->vallen  = newvallen;
  newnode->type    = newtype;
  if( self->numchildren == 0 ) {
    self->firstchild = newnode;
    self->lastchild  = newnode;
  }
  else {
    self->lastchild->next = newnode;
    self->lastchild = newnode;
  }
  self->numchildren++;
  return newnode;
}

struct attc *nodec_addattr( struct nodec *self, char *newname, int newnamelen, char *newval, int newvallen ) {
  struct attc *newatt    = new_attc( self );
  newatt->name    = newname;
  newatt->namelen = newnamelen;
  newatt->value   = newval;
  newatt->vallen  = newvallen;
  if( self->numatt == 0 ) {
    self->firstatt = newatt;
    self->lastatt  = newatt;
  }
  else {
    self->lastatt->next = newatt;
    self->lastatt = newatt;
  }
  self->numatt++;
  return newatt;
}
