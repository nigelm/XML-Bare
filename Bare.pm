package XML::Bare;

use Carp;
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);

$VERSION = "0.30";

bootstrap XML::Bare $VERSION;

@EXPORT = qw( );
@EXPORT_OK = qw(merge clean find_node del_node);

=head1 NAME

XML::Bare - Minimal XML parser implemented via a C state engine

=head1 VERSION

0.30

=cut

sub new {
  my $class = shift; 
  $class    = ref($class) || $class;
  my $self  = {};
  %$self    = @_;

  bless $self, $class;
  
  my $text;
  if( $self->{ 'text' } ) {
    XML::Bare::c_parse( $self->{'text'} );
  }
  else {
    my $file = $self->{ 'file' };
    my $res = open( XML, $file );
    if( !$res ) {
      $self->{ 'xml' } = 0;
      return 0;
    }
    {
      local $/ = undef;
      $text = <XML>;
    }
    close( XML );
    XML::Bare::c_parse( $text );
  }
  return $self;
}

sub forcearray {
  my $ref = shift;
  return $ref if( ref( $ref ) eq 'ARRAY' );
  my @arr;
  push( @arr, $ref );
  return \@arr;
}

sub merge {
  # shift in the two array references as well as the field to merge on
  my $a = shift;
  my $b = shift;
  my $id = shift;
  my %hash = map { $_->{ $id } ? ( $_->{ $id }->{ 'value' } => $_ ) : ( 0 => 0 ) } @$a;
  for my $one ( @$b ) {
    next if( !$one->{ $id } );
    my $short = $hash{ $one->{ $id }->{ 'value' } };
    next if( !$short );
    foreach my $key ( keys %$one ) {
      next if( $key eq '_pos' || $key eq 'id' );
      my $cur = $short->{ $key };
      my $add = $one->{ $key };
      if( !$cur ) {
        $short->{ $key } = $add;
      }
      else {
        my $type = ref( $cur );
        if( $cur eq 'HASH' ) {
          my @arr;
          $short->{ $key } = \@arr;
          push( @arr, $cur );
        }
        if( ref( $add ) eq 'HASH' ) {
          push( @{$short->{ $key }}, $add );
        }
        else { # we are merging an array
          push( @{$short->{ $key }}, @$add );
        }
        
      }
      # we need to deal with the case where this node
      # is already there, either alone or as an array
    }
  }
  return $a;  
}

sub clean {
  my $ob = new XML::Bare( @_ );
  my $root = $ob->parse();
  $ob->{'file'} = $ob->{'save'} if( $ob->{'save'} && "$ob->{'save'}" ne "1" );
  if( $ob->{'save'} ) {
    $ob->save();
    return;
  }
  return $ob->xml( $root );
}

# Load a file using XML::DOM, convert it to a hash, and return the hash
sub parse {
  my $self   = shift;
  
  $self->{ 'xml' } = XML::Bare::xml2obj();#$self->xml2obj();
  XML::Bare::free_tree();
  
  return $self->{ 'xml' };
}

sub simple {
  my $self   = shift;
  
  $self->{ 'xml' } = XML::Bare::xml2obj_simple();#$self->xml2obj();
  XML::Bare::free_tree();
  
  return $self->{ 'xml' };
}

sub add_node {
  my $self = shift;
  my $node = shift;
  my $name = shift;
  my @newar;
  my %blank;
  $node->{ 'multi_'.$name } = \%blank if( ! $node->{ 'multi_'.$name } );
  $node->{ $name } = \@newar if( ! $node->{ $name } );
  my $newnode = $self->new_node( @_ );
  push( @{ $node->{ $name } }, $newnode );
  return $newnode;
}

sub add_node_after {
  my $self = shift;
  my $node = shift;
  my $prev = shift;
  my $name = shift;
  my @newar;
  my %blank;
  $node->{ 'multi_'.$name } = \%blank if( ! $node->{ 'multi_'.$name } );
  $node->{ $name } = \@newar if( ! $node->{ $name } );
  my $newnode = $self->new_node( @_ );
  
  my $cur = 0;
  for my $anode ( @{ $node->{ $name } } ) {
    $anode->{'_pos'} = $cur if( !$anode->{'_pos'} );
    $cur++;
  }
  my $opos = $prev->{'_pos'};
  for my $anode ( @{ $node->{ $name } } ) {
    $anode->{'_pos'}++ if( $anode->{'_pos'} > $opos );
  }
  $newnode->{'_pos'} = $opos + 1;
  
  push( @{ $node->{ $name } }, $newnode );
  
  return $newnode;
}

sub find_by_perl {
  my $arr = shift;
  my $cond = shift;
  $cond =~ s/-([a-z]+)/\$ob->\{'$1'\}->\{'value'\}/g;
  my @res;
  foreach my $ob ( @$arr ) {
    push( @res, $ob ) if( eval( $cond ) );
  }
  return \@res;
}

sub find_node {
  my $self = shift;
  my $node = shift;
  my $name = shift;
  my %match = @_;
  $node = $node->{ $name };
  return 0 if( !$node );
  if( ref( $node ) eq 'HASH' ) {
    foreach my $key ( keys %match ) {
      my $val = $match{ $key };
      next if ( !$val );
      if( $node->{ $key }->{'value'} eq $val ) {
        return $node;
      }
    }
  }
  if( ref( $node ) eq 'ARRAY' ) {
    for( my $i = 0; $i <= $#$node; $i++ ) {
      my $one = $node->[ $i ];
      foreach my $key ( keys %match ) {
        my $val = $match{ $key };
        croak('undefined value in find') unless defined $val;
        if( $one->{ $key }->{'value'} eq $val ) {
          return $node->[ $i ];
        }
      }
    }
  }
  return 0;
}

sub del_node {
  my $self = shift;
  my $node = shift;
  my $name = shift;
  my %match = @_;
  $node = $node->{ $name };
  return if( !$node );
  for( my $i = 0; $i <= $#$node; $i++ ) {
    my $one = $node->[ $i ];
    foreach my $key ( keys %match ) {
      my $val = $match{ $key };
      if( $one->{ $key }->{'value'} eq $val ) {
        delete $node->[ $i ];
      }
    }
  }
}

sub del_by_perl {
  my $arr = shift;
  my $cond = shift;
  $cond =~ s/-value/\$ob->\{'value'\}/g;
  $cond =~ s/-([a-z]+)/\$ob->\{'$1'\}->\{'value'\}/g;
  my @res;
  for( my $i = 0; $i <= $#$arr; $i++ ) {
    my $ob = $arr->[ $i ];
    delete $arr->[ $i ] if( eval( $cond ) );
  }
  return \@res;
}

# Created a node of XML hash with the passed in variables already set
sub new_node {
  my $self  = shift;
  my %parts = @_;
  
  my %newnode;
  foreach $a ( keys %parts ) {
    $newnode{ $a } = $self->newhash( $parts{$a} );
  }
  
  return \%newnode;
}

sub newhash {
  my $self = shift;
  my $val = shift;
  my %hash;
  
  $hash{ 'value' } = $val;
  
  return \%hash;
}

sub simplify {
  my $self = shift;
  my $root = shift;
  my %ret;
  foreach my $name ( keys %$root ) {
    my $val = $root->{$name}{'value'} || '';
    $ret{ $name } = $val;
  }
  return \%ret;
}

# Save an XML hash tree into a file
sub save {
  my $self = shift;
  my $file   = $self->{ 'file' };
  my $xml    = $self->{ 'xml' };
  return if( ! $xml );
  
  open  F, '>' . $file;
  print F $self->xml( $self->{'xml'} );
  close F;
}

sub xml {
  my $self = shift;
  my $obj = shift;
  my $name = shift;
  if( !$name ) {
    my %hash;
    $hash{0} = $obj;
    return obj2xml( \%hash, '', 0 );
  }
  my %hash;
  $hash{$name} = $obj;
  return obj2xml( \%hash, '', 0 );
}

sub obj2xml {
  my $objs = shift;
  my $name = shift;
  my $pad = shift;
  my $level = shift;
  my $pdex = shift;
  $level = 0 if( !$level );
  $pad = '' if( $level == 1 );
  my $xml  = '';
  my $att  = '';
  my $imm  = 1;
  return '' if( !$objs );
  my @dex = sort
    { 
      my $oba = $objs->{ $a };
      my $obb = $objs->{ $b };
      if( !$oba ) { return 0; }
      if( !$obb ) { return 0; }
      $oba = $oba->[0] if( ref( $oba ) eq 'ARRAY' );
      $obb = $obb->[0] if( ref( $obb ) eq 'ARRAY' );
      if( ref( $oba ) eq 'HASH' && ref( $obb ) eq 'HASH' ) {
        my $posa = $oba->{'_pos'}*1;
        my $posb = $obb->{'_pos'}*1;
        if( !$posa ) { $posa = 0; }
        if( !$posb ) { $posb = 0; }
        return $posa <=> $posb;
      }
      return 0;
    } keys %$objs;
  for my $i ( @dex ) {
    my $obj  = $objs->{ $i } || '';
    my $type = ref( $obj );
    if( $type eq 'ARRAY' ) {
      $imm = 0;
      
      my @dex2 = sort
        { 
          my $oba = $a;#$obj->[ $a ];
          my $obb = $b;#$obj->[ $b ];
          if( !$oba ) { return 0; }
          if( !$obb ) { return 0; }
          if( ref( $oba ) eq 'HASH' && ref( $obb ) eq 'HASH' ) {
            my $posa = $oba->{'_pos'};
            my $posb = $obb->{'_pos'};
            if( !$posa ) { $posa = 0; }
            if( !$posb ) { $posb = 0; }
            return $posa <=> $posb;
          }
          return 0;
        } @$obj;
      
      #for( my $j = 0; $j <= $#$obj; $j++ ) {
      for my $j ( @dex2 ) {
        #$xml .= obj2xml( $obj->[ $j ], $i, $pad.'  ', $level+1, $#dex );
        $xml .= obj2xml( $j, $i, $pad.'  ', $level+1, $#dex );
      }
    }
    elsif( $type eq 'HASH' ) {
      $imm = 0;
      if( $obj->{ 'att' } ) {
        $att .= ' ' . $i . '="' . $obj->{ 'value' } . '"';
      }
      else {
        $xml .= obj2xml( $obj , $i, ( $level > 1 ) ? ( $pad.'  ' ) : '', $level+1, $#dex );
      }
    }
    else {
      if( $i eq 'comment' ) {
        $xml .= '<!--' . $obj . '-->' . "\n";
      }
      elsif( $i eq 'value' ) {
        if( $#dex < 2 && $level > 1 ) {
          if( $obj && $obj =~ /[<>&;]/ ) {
            $xml .= '<![CDATA[' . $obj . ']]>';
          }
          else {
            if( $obj =~ /\S/ ) {
              #if( $#dex == 1 ) {
              #  $obj =~ s/^\s+//;
              #  $obj =~ s/\s+$//;
              #  $obj = "$pad  $obj\n";
              #}
              $xml .= $obj;
            }
          }
        }
      }
      elsif( substr( $i, 0, 1 ) eq '_' ) {
      }
      else {
        $xml .= '<' . $i . '>' . $obj . '</' . $i . '>';
      }
    }
  }
  #$imm = 0 if( $#dex < 1 );
  #$imm = 1 if( $#dex );
  my $pad2 = $imm ? '' : $pad;
  my $cr = $imm ? '' : "\n";
  if( $name ) {
    $xml = $pad . '<' . $name . $att . '>' . $cr . $xml . $pad2 . '</' . $name . '>';
  }
  return $xml."\n" if( $level );
  return $xml;
}

1;

__END__

=head1 SYNOPSIS

  use XML::Bare;
  
  my $xml = new XML::Bare( text => '<xml><name>Bob</name></xml>' );
  
  # Parse the xml into a hash tree
  my $root = $xml->parse();
  
  # Print the content of the name node
  print $root->{xml}->{name}->{value};
  
  # Load xml from a file ( assume same contents as first example )
  my $xml2 = new XML::Bare( file => 'test.xml' );
  
  my $root2 = $xml2->parse();
  
  $root2->{xml}->{name}->{value} = 'Tim';
  
  # Save the changes back to the file
  $xml2->save();  

=head1 DESCRIPTION

This module is a 'Bare' XML parser. It is implemented in C++. The parser
itself is a simple state engine that is less than 500 lines of C++. The
parser builds a C++ class tree from input text. That C++ class tree is
converted to a Perl hash by a Perl function that makes basic calls back
to the C++ to go through the nodes sequentially.

=head2 Supported XML

To demonstrate what sort of XML is supported, consider the following
examples. Each of the PERL statements evaluates to true.

=over 2

=item * Node containing just text

  XML: <xml>blah</xml>
  PERL: $root->{xml}->{value} eq "blah";

=item * Subset nodes

  XML: <xml><name>Bob</name></xml>
  PERL: $root->{xml}->{name}->{value} eq "Bob";

=item * Attributes unquoted

  XML: <xml><a href=index.htm>Link</a></xml>
  PERL: $root->{xml}->{a}->{href}->{value} eq "index.htm";

=item * Attributes quoted

  XML: <xml><a href="index.htm">Link</a></xml>
  PERL: $root->{xml}->{a}->{href}->{value} eq "index.htm";

=item * CDATA nodes

  XML: <xml><raw><![CDATA[some raw $~<!bad xml<>]]></raw></xml>
  PERL: $root->{xml}->{raw}->{value} eq "some raw \$~<!bad xml<>";

=item * Multiple nodes; form array

  XML: <xml><item>1</item><item>2</item></xml>
  PERL: $root->{xml}->{item}->[0]->{value} eq "1";

=item * Forcing array creation

  XML: <xml><multi_item/><item>1</item></xml>
  PERL: $root->{xml}->{item}->[0]->{value} eq "1";

=item * One comment supported per node

  XML: <xml><!--test--></xml>
  PERL: $root->{xml}->{comment} eq 'test';

=back

=head2 Parsed Hash Structure

The hash structure returned from XML parsing is created in a specific format.
Besides as described above, the structure contains some additional nodes in
order to preserve information that will allow that structure to be correctly
converted back to XML.
  
Nodes may contain the following 2 additional subnodes:

=over 2

=item * _pos

This is a number indicating the ordering of nodes. It is used to allow
items in a perl hash to be sorted when writing back to xml. Note that
items are not sorted after parsing in order to save time if all you
are doing is reading and you do not care about the order.

In future versions of this module an option will be added to allow
you to sort your nodes so that you can read them in order.

=item * att

This is a boolean value that exists and is 1 iff the node is an
attribute.

=back

=head2 Parsing Limitations / Features

=over 2

=item * CDATA parsed correctly, but stripped if unneeded

Currently the contents of a node that are CDATA are read and
put into the value hash, but the hash structure does not have
a value indicating the node contains CDATA.

When converting back to XML, the contents are the value hash
are parsed to check for xml incompatible data using a regular
expression. If 'CDATA like' stuff is encountered, the node
is output as CDATA.

=item * Node position stored, but hash remains unsorted

The ordering of nodes is noted using the '_pos' value, but
the hash itself is not ordered after parsing. Currently
items will be out of order when looking at them in the
hash.

Note that when converted back to XML, the nodes are then
sorted and output in the correct order to XML. Note that
nodes of the same name with the same parent will be
grouped together; the position of the first item to
appear will determine the output position of the group.

=item * Comments are parsed but only one is stored per node.

For each node, there can be a comment within it, and that
comment will be saved and output back when dumping to XML.

=item * Comments override output of immediate value

If a node contains only a comment node and a text value,
only the comment node will be displayed. This is in line
with treating a comment node as a node and only displaying
immediate values when a node contains no subnodes.

=item * PI sections are parsed, but discarded

=item * Unknown C<< <! >> sections are parsed, but discarded

=item * Attributes may use no quotes, single quotes, quotes

=item * Quoted attributes cannot contain escaped quotes

No escape character is recognized within quotes. As a result,
regular quotes cannot be stored to XML, or the written XML
will not be correct, due to all attributes always being written
using quotes.

=item * Attributes are always written back to XML with quotes

=item * Nodes cannot contain subnodes as well as an immediate value

Actually nodes can in fact contain a value as well, but that
value will be discarded if you write back to XML. That value is
equal to the first continuous string of text besides a subnode.

  <node>text<subnode/>text2</node>
  ( the value of node is text )

  <node><subnode/>text</node>
  ( the value of node is text )

  <node>
    <subnode/>text
  </node>
  ( the value of node is "\n  " )

=back

=head2 Module Functions

=over 2

=item * C<< $ob = new XML::Bare( text => "[some xml]" ) >>

Create a new XML object, with the given text as the xml source.

=item * C<< $object = new XML::Bare( file => "[filename]" ) >>

Create a new XML object, with the given filename/path as the xml source

=item * C<< $object = new XML::Bare( text => "[some xml]", file => "[filename]" ) >>

Create a new XML object, with the given text as the xml input, and the given
filename/path as the potential output ( used by save() )

=item * C<< $tree = $object->parse() >>

Parse the xml of the object and return a tree reference

=item * C<< $tree = $object->simple() >>

Alternate to the parse function which generates a tree similar to that
generated by XML::Simple. Note that the sets of nodes are turned into
arrays always, regardless of whether they have a 'name' attribute, unlike
XML::Simple.

Note that currently the generated tree cannot be used with any of the
functions in this module that operate upon trees. The function is provided
purely as a quick and dirty way to read simple XML files.

Also note that you cannot rely upon this function being contained in
future versions of XML::Bare; the function will likely be split off into
an optimized version meant purely to operate in this fashion.

=item * C<< $text = $object->xml( [root] ) >>

Take the hash tree in [root] and turn it into cleanly indented ( 2 spaces )
XML text.

=item * C<< $object->save() >>

The the current tree in the object, cleanly indent it, and save it
to the file paramter specified when creating the object.

=item * C<< $text = XML::Bare::clean( text => "[some xml]" ) >>

Shortcut to creating an xml object and immediately turning it into clean xml text.

=item * C<< $text = XML::Bare::clean( file => "[filename]" ) >>

Similar to previous.

=item * C<< XML::Bare::clean( file => "[filename]", save => 1 ) >>

Clean up the xml in the file, saving the results back to the file

=item * C<< XML::Bare::clean( text => "[some xml]", save => "[filename]" ) >>

Clean up the xml provided, and save it into the specified file.

=item * C<< XML::Bare::clean( file => "[filename1]", save => "[filename2]" ) >>

Clean up the xml in filename1 and save the results to filename2.

=item * C<< $object->add_node( [node], [nodeset name], name => value, name2 => value2, ... ) >>

  Example:
    $object->add_node( $root->{xml}, 'item', name => 'Bob' );
    
  Result:
    <xml>
      <item>
        <name>Bob</name>
      </item>
    </xml>
    
=item * C<< $oject->add_node_after( [node], [prev node], [nodeset name], name => value, name2 => value2, ... ) >>

Similar to add_node above, but adds the node immediately after the passed [prev node].

=item * C<< $object->del_node( [node], [nodeset name], name => value ) >>

  Example:
    Starting XML:
      <xml>
        <a>
          <b>1</b>
        </a>
        <a>
          <b>2</b>
        </a>
      </xml>
      
    Code:
      $xml->del_node( $root->{xml}, 'a', b=>'1' );
    
    Ending XML:
      <xml>
        <a>
          <b>2</b>
        </a>
      </xml>

=item * C<< $object->find_node( [node], [nodeset name], name => value ) >>

  Example:
    Starting XML:
      <xml>
        <ob>
          <key>1</key>
          <val>a</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </xml>
      
    Code:
      $object->find_node( $root->{xml}, 'ob', key => '1' )->{val}->{value} = 'test';
      
    Ending XML:
      <xml>
        <ob>
          <key>1</key>
          <val>test</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </xml>

=item * C<< $object->find_by_perl( [nodeset], "[perl code]" ) >>

find_by_perl evaluates some perl code for each node in a set of nodes, and
returns the nodes where the perl code evaluates as true. In order to
easily reference node values, node values can be directly referred
to from within the perl code by the name of the node with a dash(-) in
front of the name. See the example below.

Note that this function returns an array reference as opposed to a single
node unlike the find_node function.

  Example:
    Starting XML:
      <xml>
        <ob>
          <key>1</key>
          <val>a</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </xml>
      
    Code:
      $object->find_by_perl( $root->{xml}->{ob}, "-key eq '1'" )->[0]->{val}->{value} = 'test';
      
    Ending XML:
      <xml>
        <ob>
          <key>1</key>
          <val>test</val>
        </ob>
        <ob>
          <key>2</key>
          <val>b</val>
        </ob>
      </xml>

=item * C<< XML::Bare::merge( [nodeset1], [nodeset2], [id node name] ) >>

Merges the nodes from nodeset2 into nodeset1, matching the contents of
each node based up the content in the id node.

Example:

  Code:
    my $ob1 = new XML::Bare( text => "
      <xml>
        <multi_a/>
        <a>bob</a>
        <a>
          <id>1</id>
          <color>blue</color>
        </a>
      </xml>" );
    my $ob2 = new XML::Bare( text => "
      <xml>
        <multi_a/>
        <a>john</a>
        <a>
          <id>1</id>
          <name>bob</name>
          <bob>1</bob>
        </a>
      </xml>" );
    my $root1 = $ob1->parse();
    my $root2 = $ob2->parse();
    merge( $root1->{'xml'}->{'a'}, $root2->{'xml'}->{'a'}, 'id' );
    print $ob1->xml( $root1 );
  
  Output:
    <xml>
      <multi_a></multi_a>
      <a>bob</a>
      <a>
        <id>1</id>
        <color>blue</color>
        <name>bob</name>
        <bob>1</bob>
      </a>
    </xml>

=item * C<< XML::Bare::del_by_perl( ... ) >>

Works exactly like find_by_perl, but deletes whatever matches.

=item * C<< XML::Bare::forcearray( [noderef] ) >>

Turns the node reference into an array reference, whether that
node is just a single node, or is already an array reference.

=item * C<< XML::Bare::new_node( ... ) >>

Creates a new node...

=item * C<< XML::Bare::newhash( ... ) >>

Creates a new hash with the specified value.

=item * C<< XML::Bare::simplify( [noderef] ) >>

Take a node with children that have immediate values and
creates a hashref to reference those values by the name of
each child.

=back

=head2 Functions Used Internally

=over 2

=item * C<< XML::Bare::c_parse() >>

=item * C<< XML::Bare::c_parsefile() >>

=item * C<< XML::Bare::free_tree() >>

=item * C<< XML::Bare::xml2obj() >>

=item * C<< XML::Bare::xml2obj_simple() >>

=item * C<< XML::Bare::obj2xml() >>

=back

=head2 Performance

In comparison to other available perl xml parsers that create trees, XML::Bare
is extremely fast. In order to measure the performance of loading and parsing
compared to the alternatives, a templated speed comparison mechanism has been
created and included with XML::Bare.

The include makebench.pl file runs when you make the module and creates perl
files within the bench directory corresponding to the .tmpl contained there.

Currently there are three types of modules that can be tested against,
executable parsers ( exe.tmpl ), tree parsers ( tree.tmpl ), and parsers
that do not generated trees ( notree.tmpl ).

A full list of modules currently tested against is as follows:

=over 2

=item * Tiny XML (exe)

=item * EzXML (exe)

=item * XMLIO (exe)

=item * XML::LibXML (notree)

=item * XML::Parser (notree)

=item * XML::Parser::Expat (notree)

=item * XML::Descent (notree)

=item * XML::Parser::EasyTree

=item * XML::Handler::Trees

=item * XML::Twig

=item * XML::Smart

=item * XML::Simple

=item * XML::TreePP

=item * XML::Trivial

=item * XML::SAX::Simple

=item * XML::Grove::Builder

=item * XML::XPath::XMLParser

=back

To run the comparisons, run the appropriate perl file within the
bench directory. (exe.pl, tree.pl, or notree.pl )

The script measures the milliseconds of loading and parsing, and
compares the time against the time of XML::Bare. So a 7 means
it takes 7 times as long as XML::Bare.

Here is a combined table of the script run against each alternative
using the included test.xml:

  -Module-                   load     parse    total
  XML::Bare                  1        1        1
  XML::TreePP                2.3063   33.1776  6.1598
  XML::Parser::EasyTree      4.9405   25.7278  7.4571
  XML::Handler::Trees        7.2303   26.5688  9.6447
  XML::Trivial               5.0636   12.4715  7.3046
  XML::Smart                 6.8138   78.7939  15.8296
  XML::Simple                2.7115   195.9411 26.5704
  XML::SAX::Simple           8.7792   170.7313 28.3634
  XML::Twig                  27.8266  56.4476  31.3594
  XML::Grove::Builder        7.1267   26.1672  9.4064
  XML::XPath::XMLParser      9.7783   35.5486  13.0002
  XML::LibXML (notree)       11.0038  4.5758   10.6881
  XML::Parser (notree)       4.4698   17.6448  5.8609
  XML::Parser::Expat(notree) 3.7681   50.0382  6.0069
  XML::Descent (notree)      6.0525   37.0265  11.0322
  Tiny XML (exe)                               1.0095
  EzXML (exe)                                  1.1284
  XMLIO (exe)                                  1.0165

Here is a combined table of the script run against each alternative
using the included feed2.xml:

  -Module-                   load     parse    total
  XML::Bare                  1        1        1
  XML::TreePP                2.3068   23.7554  7.6921
  XML::Parser::EasyTree      4.8799   25.3691  9.6257
  XML::Handler::Trees        6.8545   33.1007  13.0575
  XML::Trivial               5.0105   32.0043  11.4113
  XML::Smart                 6.8489   45.4236  16.2809
  XML::Simple                2.7168   90.7203  26.7525
  XML::SAX::Simple           8.7386   94.8276  29.2166
  XML::Twig                  28.3206  48.1014  33.1222
  XML::Grove::Builder        7.2021   30.7926  12.9334
  XML::XPath::XMLParser      9.6869   43.5032  17.4941
  XML::LibXML (notree)       11.0023  5.022    10.5214
  XML::Parser (notree)       4.3748   25.0213  5.9803
  XML::Parser::Expat(notree) 3.6555   51.6426  7.4316
  XML::Descent (notree)      5.9206   155.0289 18.7767
  Tiny XML (exe)                               1.2212
  EzXML (exe)                                  1.3618
  XMLIO (exe)                                  1.0145

These results show that XML::Bare is, at least on the
test machine, running all tests within cygwin, faster
at loading and parsing than everything being tested
against.

The following things are shown as well:
  - XML::Bare can parse XML and create a hash tree
  in less time than it takes LibXML just to parse.
  - XML::Bare can parse XML and create a hash tree
  in less time than all three binary parsers take
  just to parse.

Note that the executable parsers are not perl modules
and are timed using dummy programs that just uses the
library to load and parse the example files. The files
created to do such testing are available upon request.

=head1 LICENSE

  Copyright (C) 2007 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
