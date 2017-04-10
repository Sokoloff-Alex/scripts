#!/bin/bash
#
# get availability of RINEX data in pseudographics
#
# 

cat $1 | cut -c1-4 | sort | uniq --count
