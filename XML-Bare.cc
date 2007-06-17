#include "parser.cc"

  extern "C" void parse( char *text );
  extern "C" int num_nodes();
  extern "C" void descend();
  extern "C" void ascend();
  extern "C" void next_node();
  extern "C" char *node_name();
  extern "C" char *node_value();
  extern "C" int node_type();
  extern "C" int num_att();
  extern "C" void first_att();
  extern "C" void next_att();
  extern "C" char *att_name();
  extern "C" char *att_value();

parserc parser;
void parse( char *text ) { parser.parse( text ); }
int  num_nodes  () { return parser.num_nodes (); }
void descend    () {        parser.descend   (); }
void ascend     () {        parser.ascend    (); }
void next_node  () {        parser.next_node (); }
char *node_name () { return parser.node_name (); }
char *node_value() { return parser.node_value(); }
int  node_type  () { return parser.node_type (); }
void first_att  () {        parser.first_att (); }
void next_att   () {        parser.next_att  (); }
char *att_name  () { return parser.att_name  (); }
char *att_value () { return parser.att_value (); }
int  num_att    () { return parser.num_att   (); }

