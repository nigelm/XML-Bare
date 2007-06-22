#include "parser.c"
struct parserc parser;
struct nodec *root;
void parse( char *text ) { parserc_parse( &parser, text ); root = parser.pcurnode; }

void descend    () {        parserc_descend   (&parser); }
void ascend     () {        parserc_ascend    (&parser); }
void next_node  () {        parserc_next_node (&parser); }
void first_att  () {        parserc_first_att (&parser); }
void next_att   () {        parserc_next_att  (&parser); }

int  num_att    () { return parserc_num_att   (&parser); }
int  node_type  () { return parserc_node_type (&parser); }
int  num_nodes  () { return parserc_num_nodes (&parser); }

char *att_name  () { return parserc_att_name  (&parser); }
char *att_value () { return parserc_att_value (&parser); }
char *node_name () { return parserc_node_name (&parser); }
char *node_value() { return parserc_node_value(&parser); }

void free_tree  () { del_nodec( root ); }
