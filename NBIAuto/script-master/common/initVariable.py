#!/usr/bin/python
#This script is ussed for substitue config file to STAF variable pool
#Writen on Oct.25th 2013

import os
import sys
import commands
import ConfigParser

def Pname(pro):
  sections=config.sections()
  sections.remove('Identifier')
  for i in sections:
    flag=config.get(i,'flag')
    options=config.options(i)
    options.remove('flag')
    for opts in options:
      value=config.get(i,opts)
      rname="%s.%s.%s&%s" %(pro,i,opts,flag)
      Cmd(rname,value)

def Exception(input,name,status,ip):
  if input.find('Error') != -1:
      print "[ERROR]%s %s setting %s failed !" %(status,ip,name)
  else:
      print "%s %s setting %s success !" %(status,ip,name)

def RemoteSetVar(name,value):
  for remoteip in remoteipList:
    remote_exe=commands.getoutput('staf %s var SET system var %s=%s' %(remoteip,name,value))
    Exception(remote_exe,name,'Remote',remoteip)

def Cmd(rname,value):  
  flag=rname.split("&")[1]
  name=rname.split("&")[0]
  if flag=='both':
    RemoteSetVar(name,value)
#    remote_exe=commands.getoutput('staf %s var SET system var %s=%s' %(remoteip,name,value))
#    Exception(remote_exe,name)
    local_exe=commands.getoutput('staf local var SET system var %s=%s' %(name,value))
    Exception(local_exe,name,'Local','')
  elif flag=='master':
    local_exe=commands.getoutput('staf local var SET system var %s=%s' %(name,value))
    Exception(local_exe,name,'Local','')
  elif flag=='client':
    RemoteSetVar(name,value)
#    remote_exe=commands.getoutput('staf %s var SET system var %s=%s' %(remoteip,name,value))
#    Exception(remote_exe,name)
  else:
    print "[ERROR]Found a wrong flag value [%s] in configuration file, the value only can be 'both/master/client'." %(flag)

if __name__=="__main__":
  if len(sys.argv) != 2:
    print "Usage: python %s <config_file_name>\nExit !\n" %(sys.argv[0])
    exit(0)
  configfile=sys.argv[1]
  if os.path.isfile(configfile) == 'False':
    print "Can not find config file:%s\nExit !" % (configfile)
    sys.exit(1)
  config=ConfigParser.ConfigParser()
  config.read(configfile)
  global remoteip
  if commands.getoutput("cat %s |grep Remoteip" % (configfile))!= " ":
    remoteipList=config.get('DataCollection','Remoteip').split(" ")
    print "remoteipList==",remoteipList
  pro=config.get('Identifier','ID')
  prolist=pro.split(",")
  for pro in prolist:
    Pname(pro)

