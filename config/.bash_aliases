# make any executable placed in ~/bin discoverable 

#check if ~/bin directory exists and if not create one
if [ ! -d "$HOME/bin" ] ; then
    mkdir $HOME/bin
fi

#add ~/bin to variable $PATH specifying location(s) of executables 
export PATH="$HOME/bin:$PATH"

#Section deleted in version 4.0 gardenpi command re-written
# check if gardenpi.sh file exist if not create one
#if [ ! -f "$HOME/bin/.gardenpi.sh" ] ; then
#    echo "#!/bin/bash" > $HOME/bin/.gardenpi.sh
#    echo "cat /etc/motd" >> $HOME/bin/.gardenpi.sh
#    #make gardenpi.sh script executable
#    chmod +x $HOME/bin/.gardenpi.sh
#    #create dynamic link
#    ln -s $HOME/bin/.gardenpi.sh $HOME/bin/gardenpi
#fi
