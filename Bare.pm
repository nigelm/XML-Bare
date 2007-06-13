package XML::Bare;

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);

package XML::Barec;
bootstrap XML::Bare;
package XML::Bare;

@EXPORT = qw( );

$VERSION = "0.02";
# revision A

sub new {
  my $class = shift; 
  $class    = ref($class) || $class;
  my $self  = {};
  %$self    = @_;

  bless $self, $class;
  
  return $self;
}

# Load a file using XML::DOM, convert it to a hash, and return the hash
sub parse {
  my $self   = shift;
  my $text;
  if( $self->{ 'text' } ) {
    $text = $self->{ 'text' };
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
  }
  
  XML::Barec::parse( $text );
  $self->{ 'xml' } = $self->xml2obj();
  
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
  push( @{ $node->{ $name } }, $self->new_node( @_ ) );
}

sub find_node {
  my $self = shift;
  my $node = shift;
  my $name = shift;
  my %match = @_;
  $node = $node->{ $name };
  return 0 if( !$node );
  for( my $i = 0; $i <= $#$node; $i++ ) {
    my $one = $node->[ $i ];
    foreach my $key ( keys %match ) {
      my $val = $match{ $key };
      if( $one->{ $key }->{'value'} eq $val ) {
        return $node->[ $i ];
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

# Save an XML hash tree into a file
# Note we should use XML::Twig into order to beautify this before outputting
sub save {
  my $self = shift;
  my $file   = $self->{ 'file' };
  my $xml    = $self->{ 'xml' };
  return if( ! $xml );
  
  #my $xmltxt = obj2xml( $xml, '' );
  
  open  F, '>' . $file;
  print F $self->xml( $self->{'xml'} );
  close F;
}

sub xml2obj {
  my %output;
  my %outnodes;
  my @outnodenames;
  my $length = XML::Barec::num_nodes();
  
  if( $length == 0 ) {
    my $nodename = XML::Barec::node_name();
    my $nodevalue = XML::Barec::node_value();
    $output{ 'value' } = $nodevalue;
  }
  else {
    my $nodevalue = XML::Barec::node_value();
    $output{ 'value' } = $nodevalue;
    XML::Barec::descend();
    for( my $i = 0; $i < $length; $i++ ) {
      my $nodename = XML::Barec::node_name();
      
      if( !$outnodes{ $nodename } ) {
        my @newarray;
        $outnodes{ $nodename } = \@newarray;
        push( @outnodenames, $nodename );
      }
      my $nodea = $outnodes{ $nodename };
      push( @$nodea, xml2obj() );
      
      XML::Barec::next_node() if( $i != ( $length - 1 ) );
    }
    
    for( my $i = 0; $i <= $#outnodenames; $i++ ) {
      my $name = $outnodenames[ $i ]; # the name of this node
      my $part = $outnodes{ $name };  # the parsed contents ( the array of these nodes )
      my $num  = $#$part;
      $num++;
      if( $num > 1 || $outnodes{ 'multi_' . $name } ) {
        my @newarray;
        $output{ $name } = \@newarray;
        for( my $i2 = 0; $i2 < $num; $i2++ ) {
          push( @newarray, $part->[ $i2 ] );
        }
      }
      else {
        $output{ $name } = $part->[ 0 ];
        if( ref( $output{$name} ) eq 'HASH' ) {
          $output{ $name }->{'pos'} = $i;
        }
      }
    }
      
    XML::Barec::ascend();
  }
  
  my $numatts = XML::Barec::num_att();
  if( $numatts ) {
    XML::Barec::first_att();
    for( my $i = 0; $i < $numatts; $i++ ) {
      my %newhash;
      $output{ XML::Barec::att_name() } = \%newhash;
      $newhash{ 'value' } = XML::Barec::att_value();
      $newhash{ 'att'   }   = 1;
      XML::Barec::next_att() if( $i != ( $numatts - 1 ) );
    }
  }
  
  return \%output;
}

sub xml {
  my $self = shift;
  my $obj = shift;
  return obj2xml( $obj, '', 0 );
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
  my $imm  = 0;
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
      for( my $j = 0; $j <= $#$obj; $j++ ) {
        $xml .= obj2xml( $obj->[ $j ], $i, $pad.'  ', $level+1 );
      }
    }
    elsif( $type eq 'HASH' ) {
      if( $obj->{ 'att' } ) {
        $att .= ' ' . $i . '="' . $obj->{ 'value' } . '"';
      }
      else {
        $xml .= obj2xml( $obj , $i, $pad.'  ', $level+1 );
      }
    }
    else {
      if( $i eq 'value' ) {
        $imm = 1;
        if( $obj && $obj =~ /[<>&;]/ ) {
          $xml .= '<![CDATA[' . $obj . ']]>';
        }
        else {
          $xml .= $obj;
        }
      }
      else {
        $xml .= '<' . $i . '>' . $obj . '</' . $i . '>' if( $i ne 'pos' );
      }
    }
  }
  $imm = 1 if( ! $#dex );
  my $pad2 = $imm ? '' : $pad;
  my $cr = $imm ? '' : "\n";
  if( $name ) {
    $xml = $pad . '<' . $name . $att . '>' . $cr . $xml . $pad2 . '</' . $name . '>';
  }
  return $xml."\n";
}

1;

__END__

=head1 NAME

XML::Bare - Minimal XML parser implemented via a C++ state engine

=head1 VERSION

0.02

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

Note that when converted but to XML, the nodes are then
sorted and output in the correct order to XML.

=item * Comments are parsed, but discarded

Comments can exist in the XML, but they are thrown
away during parsing.

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

  $xml->parse();
  
  $xml->add_node( $root->{xml}, 'item', name => 'Bob' );
  <xml><item><name>Bob</name></item></xml>
  
  <xml> <a><b>1</b></a> <a><b>2</b></a> </xml>
  $xml->del_node( $root->{xml}, 'a', b=>'1' );
  <xml> <a><b>2</b></a> </xml>
  
  <xml> <ob> <key>1</key> <val>a</val> </ob> <ob> <key>2</key> <val>b</val> </ob> </xml>
  $xml->find_node( $root->{xml}, 'ob', key => '1' )->{val}->{value} = 'test';
  <xml> <ob> <key>1</key> <val>test</val> </ob> <ob> <key>2</key> <val>b</val> </ob> </xml>
  
  print $xml->xml( $root );
  ( prints clean xml output )
  
  $xml->save();
  ( saves to file location specified when xml object created ):q

=head1 LICENSE

XML::Bare version 0.02
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
