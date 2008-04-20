#!/bin/bash
perl test.pl 15
for (( i=1;i<=12;i++ )); do
perl test.pl $i $1 | grep '\.'
done