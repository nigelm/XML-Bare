package XML::Bare;

use Carp;
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);

$VERSION = "0.23";

bootstrap XML::Bare $VERSION;

@EXPORT = qw( );
@EXPORT_OK = qw(merge clean find_node del_node);

=head1 NAME

XML::Bare - Minimal XML parser implemented via a C state engine

=head1 VERSION

0.23

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
      next if( $key eq 'pos' || $key eq 'id' );
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
    return obj2xml( $obj, '', 0 );
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
      if( ref( $oba ) eq 'HASH' && ref( $obb ) eq 'HASH' ) {
        my $posa = $oba->{'pos'};
        my $posb = $obb->{'pos'};
        if( !$posa ) { $posa = 0; }
        if( !$posb ) { $posb = 0; }
        return $posa cmp $posb;
      }
      return 0;
    } keys %$objs;
  for my $i ( @dex ) {
    my $obj  = $objs->{ $i } || '';
    my $type = ref( $obj );
    if( $type eq 'ARRAY' ) {
      $imm = 0;
      for( my $j = 0; $j <= $#$obj; $j++ ) {
        $xml .= obj2xml( $obj->[ $j ], $i, $pad.'  ', $level+1 );
      }
    }
    elsif( $type eq 'HASH' ) {
      $imm = 0;
      if( $obj->{ 'att' } ) {
        $att .= ' ' . $i . '="' . $obj->{ 'value' } . '"';
      }
      else {
        $xml .= obj2xml( $obj , $i, $pad.'  ', $level+1 );
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
            $xml .= $obj;
          }
        }
      }
      else {
        $xml .= '<' . $i . '>' . $obj . '</' . $i . '>' if( $i ne 'pos' );
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

=item * pos

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

The ordering of nodes is noted using the 'pos' value, but
the hash itself is not ordered after parsing. Currently
items will be out of order when looking at them in the
hash.

Note that when converted back to XML, the nodes are then
sorted and output in the correct order to XML.

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

=item * Attributes must use double quotes if quoted

Attributes in XML can be used, with or without quotes, but
if quotes are used they must be double quotes. If single
quotes are used, the value will end up starting with a single
quote and continue until a space or a node end.

=item * Quoted attributes cannot contain escaped quotes

No escape character is recognized within quotes. As a result,
there is no way to store a double quote character in an
attribute value.

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


=back

=head2 Performance

In comparison to other available perl xml parsers that create trees, XML::Bare
is extremely fast. In order to measure the performance of loading and parsing
compared to the alternatives, a test script has been created and is included
with the distribution as 'test.pl'.

The test script can compare the speed of XML::Bare against the following
alternatives:

=over 2

=item * XML::Parser::EasyTree

=item * XML::Handler::Trees

=item * XML::Twig

=item * XML::LibXML

Note that basic LibXML is included in the comparison, despite the
fact that it does not create a tree.

=item * XML::Smart

=item * XML::Simple

=back

To run the comparison, you must provide a number, 1-12, as a paramter
to the script in order to choose which module to compare against. The
script works this way because some of the modules have parts used by
the other modules, which hides the loading time for the module tested
later...

The script measures the milliseconds of loading and parsing, and
compares the time against the time of XML::Bare. So a 7 means
it takes 7 times as long as XML::Bare.

Here is a combined table of the script run against each alternative
using the included test.xml:

  -Module-              load     parse    total
  XML::Bare             1        1        1
  XML::Parser::EasyTree 5.6811   29.2881  8.5366
  XML::Handler::Trees   7.8083   30.1434  10.503
  XML::Twig             31.0709  60.7735  34.5892
  XML::LibXML (no tree) 13.1591  1.8211   11.7857
  XML::Smart            6.9198   93.2242  17.1124
  XML::Simple           3.4242   207.0007 29.5704
  XML::SAX::Simple      9.82     191.0584 31.1326
  XML::Trivial          5.8321   7.009    6.3731
  XML::TreePP           2.5766   35.0588  6.4429
  XML::XPath::XMLParser 12.4321  41.0182  16.651
  XML::DOM::Lite        16.3544  14.8667  16.1905
  TinyXML                                 4.2033

Here is a combined table of the script run against each alternative
using the included feed2.xml:

  -Module-              load     parse    total
  XML::Bare             1        1        1
  XML::Parser::EasyTree 5.442    23.234   10.0313
  XML::Handler::Trees   5.9811   20.5755  9.6939
  XML::Twig             32.0006  44.811   35.3799
  XML::LibXML (no tree) 13.5665  1.2518   10.0492
  XML::Smart            6.8234   42.8422  16.2711
  XML::Simple           3.9487   111.1732 31.6937
  XML::SAX::Simple      10.1525  90.7282  32.7888
  XML::Trivial          5.7941   28.5549  11.7381
  XML::TreePP           2.8155   4.5963   3.9556
  XML::XPath::XMLParser 11.9291  63.184   26.5266
  XML::DOM::Lite        17.1702  13.8642  16.286
  TinyXML                                 6.5016

These results show that XML::Bare is, at least on the test machine,
~3-30 times faster loading and ~10-150 times faster parsing than
any of the alternative tree parsers.

The following are shown as well:
  - XML::Bare can parse XML and create a hash tree
  in less time than it takes LibXML just to parse.
  - XML::Bare can parse XML and create a hash tree
  in 1/4 the time it takes TinyXML just to parse

Note that TinyXML is not a perl module and is timed
by a dummy program that just uses the library to
load and parse the example files.

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
