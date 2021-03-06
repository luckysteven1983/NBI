# Author: eyujche
# Date:  2013-11-05
# Description: This function used for staf system variable fetch, load this common function at the top 
#              of your shell such as script import_common_fun.example
# Example:
#       GitHome=`getSTAFVariableValue "ONV.DataCollection.gitrepositoryhome"`


getSTAFVariableValue()
{
_parameter=$1
_loc=$2

STAFReturn=`staf "$_loc" var get system var "$_parameter"`

echo $STAFReturn |grep Error 
 
if [ $? -eq 0 ]
then
   echo $_parameter not found
   exit 1
else
   returnValue=`echo $STAFReturn|awk '{print $3}'`
   echo $returnValue
   exit 0
fi
}
