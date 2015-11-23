#!/bin/bash - 
#===============================================================================
#
#          FILE: common.sh
# 
#         USAGE: . ./common.sh 
# 
#   DESCRIPTION: An library of common script functions for Chambana docker.
# 
#        AUTHOR: Josh King 
#  ORGANIZATION: Acorn Active Media Foundation
#       CREATED: 09/28/2015 14:22
#===============================================================================

set -o nounset                              # Treat unset variables as an error

## Prettify alert messages
function MSG() {
  local i='\033[1;32m(\033[0;32m(\033[1;30m(\033[mi\033[1;30m)\033[0;32m)\033[1;32m)\033[m'
  local r='\033[0;31m'
  local n='\033[0m'
  echo -e "${i}${r} $1$n" 
}
