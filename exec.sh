#!/usr/bin/env bash

SCRIPTDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
source $SCRIPTDIR/conf.sh

useropt="-u $CONTAINERUSER"
EXECCMD=/bin/bash
while getopts ":hipr" opt; do
  case $opt in
    i)
      runopt='-it '
      docker rm $CONTAINERNAME 2>/dev/null
      ;;
    p)
      print="True"
      ;;
    r)
      useropt='-u 0 --privileged'
      ;;
    *)
      echo "usage: $0 [-h] [-i] [-p] [-r] [cmd]
   -h  print this help text
   -i  start in interactive mode and remove container afterward
   -p  print docker run command on stdout
   -r  start command as root user (default is $CONTAINERUSER)
   cmd shell command to be executed (default is $EXECCMD)"
      exit 0
      ;;
  esac
done

shift $((OPTIND-1))

if [ -z "$1" ]; then
    cmd=$EXECCMD
else
    cmd=$@
fi
docker_exec="docker exec $runopt $useropt $CONTAINERNAME $cmd"

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi
if [ "$print" = "True" ]; then
    echo $docker_exec
fi
${sudo} $docker_exec
