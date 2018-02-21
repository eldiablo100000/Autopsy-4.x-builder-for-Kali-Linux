#!/bin/bash
workingdir=`pwd`
cd autopsy
export TSK_HOME=$workingdir/tsk
ant run
