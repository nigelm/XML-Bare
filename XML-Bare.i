%{
  extern void parse( char *text );
  extern int num_nodes();
  extern void descend();
  extern void ascend();
  extern void next_node();
  extern char *node_name();
  extern char *node_value();
  extern int node_type();
  extern int num_att();
  extern void first_att();
  extern void next_att();
  extern char *att_name();
  extern char *att_value();
%}

extern void parse( char *text );
extern int num_nodes();
extern void descend();
extern void ascend();
extern void next_node();
extern char *node_name();
extern char *node_value();
extern int node_type();
extern int num_att();
extern void first_att();
extern void next_att();
extern char *att_name();
extern char *att_value();