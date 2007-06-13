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


#ifndef NULL
  #define NULL 0x00
#endif

class attc;

class nodec {
  public:
  nodec *curchild;
  nodec *parent;
  nodec *next;
  nodec *firstchild;
  nodec *lastchild;
  attc  *firstatt;
  attc  *lastatt;
  int   numchildren;
  int   numatt;
  char  *name;
  int   namelen;
  char  *value;
  int   vallen;
  int   type; // cdata or normal
  int   numvals;
  nodec( nodec *newparent );
  nodec();
  nodec *addchild( char *newname, int newnamelen ) { return addchild(newname,newnamelen,0,0,0); };
  nodec *addchild( char *newname, int newnamelen, char *newval, int newvallen, int newtype );
  attc  *addatt  ( char *newname, int newnamelen ) { return addatt( newname, newnamelen, 0, 0 ); };
  attc  *addatt  ( char *newname, int newnamelen, char *newval, int newvallen );
};

class attc {
  public:
  nodec *parent;
  attc  *next;
  char  *name;
  int   namelen;
  char  *value;
  int   vallen;
  attc( nodec *newparent );
};

class parserc {
  nodec *pcurnode;
  attc  *curatt;
  public:
  nodec *parse( char *newbuf );
  void  descend    () { pcurnode = pcurnode->firstchild;  };
  void  ascend     () { pcurnode = pcurnode->parent;      };
  int   num_nodes  () { return     pcurnode->numchildren; };
  int   num_att    () { return     pcurnode->numatt;      };
  void  next_node  () { pcurnode = pcurnode->next;        };
  void  next_att   () { curatt   = curatt  ->next;        };
  void  first_att  () { curatt   = pcurnode->firstatt;    };
  int   node_type  () { return     pcurnode->type;        };
  char  *node_name ();
  char  *node_value();
  char  *att_name  ();
  char  *att_value ();
};

char *parserc::node_name() {
  if( !pcurnode->name ) return "";
  int len = pcurnode->namelen;
  if( !len ) return "";
  pcurnode->name[ len ] = 0x00;
  return pcurnode->name;
}

char *parserc::node_value() {
  if( !pcurnode->value ) return "";
  int len = pcurnode->vallen;
  if( !len ) return "";
  pcurnode->value[ len ] = 0x00;
  return pcurnode->value;
}

char *parserc::att_name() {
  int len = curatt->namelen;
  if(!len) return "";
  curatt->name[ curatt->namelen ] = 0x00;
  return curatt->name;
}

char *parserc::att_value() {
  int len = curatt->vallen;
  if(!len) return "";
  curatt->value[ curatt->vallen ] = 0x00;
  return curatt->value;
}

nodec::nodec( nodec *newparent ) {
  next        = NULL;
  parent      = newparent;
  firstchild  = NULL;
  lastchild   = NULL;
  numchildren = 0;
  numatt      = 0;
  namelen     = 0;
  vallen      = 0;
  numvals     = 0;
}

nodec::nodec() {
  next        = NULL;
  parent      = NULL;
  firstchild  = NULL;
  lastchild   = NULL;
  numchildren = 0;
  numatt      = 0;
  name        = 0x00;
  value       = 0x00;
  namelen     = 0;
  vallen      = 0;
}

attc::attc( nodec *newparent ) {
  next    = NULL;
  parent  = newparent;
  namelen = 0;
  vallen  = 0;
  name    = 0x00;
  value   = 0x00;
}

nodec* parserc::parse( char *xmlin ) {
    nodec *root = new nodec;
    
    char  *tagname, *attname, *attval, *val;
    int   pos         = 0;
    int   state       = QK_VAL_1;
    int   tagname_len = 0;
    int   attname_len = 0;
    int   attval_len  = 0;
    nodec *curnode    = root;
    attc  *curatt     = NULL;
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
                    curnode                = curnode->addchild( tagname, tagname_len );
                    state                  = QK_NAME_GAP;
                    attname_len            = 0;
                }
                else if( let == '>' ) {
                    curnode                = curnode->addchild( tagname, tagname_len );
                    state                  = QK_VAL_1;
                }
                else if( let == '/' ) {
                    state                  = QK_VAL_1;
                    curnode->addchild( tagname, tagname_len );
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
                curatt = curnode->addatt( attname, attname_len );
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
    pcurnode = root;
    pcurnode->curchild = pcurnode->firstchild;
    return root;
}

nodec *nodec::addchild( char *newname, int newnamelen, char *newval, int newvallen, int newtype ) {
  nodec *newnode   = new nodec( this );
  newnode->name    = newname;
  newnode->namelen = newnamelen;
  newnode->value   = newval;
  newnode->vallen  = newvallen;
  newnode->type    = newtype;
  if( numchildren == 0 ) {
    firstchild = newnode;
    lastchild  = newnode;
  }
  else {
    lastchild->next = newnode;
    lastchild = newnode;
  }
  numchildren++;
  return newnode;
}

attc *nodec::addatt( char *newname, int newnamelen, char *newval, int newvallen ) {
  attc *newatt    = new attc( this );
  newatt->name    = newname;
  newatt->namelen = newnamelen;
  newatt->value   = newval;
  newatt->vallen  = newvallen;
  if( numatt == 0 ) {
    firstatt = newatt;
    lastatt  = newatt;
  }
  else {
    lastatt->next = newatt;
    lastatt = newatt;
  }
  numatt++;
  return newatt;
}
