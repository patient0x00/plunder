#################################################################
#       Developed by: Aaron Criswell                            #
#       01 October, 2013                                        #
#                                                               #
#       Script mounts nfs shares from a given IP or list        #
#       of IPs. It then creates output files for each share,    #  
#       listing all instances of the keyword(s) being           #
#       searched for.                                           #
#                                                               #
#################################################################



function PLUNDER_INSTALL {

    echo -n  "Do you want to permanently install plunder? (Y/N) >>: "
    read ANSWER
    if [[ `echo $ANSWER | grep -i "n"` ]]; then
        exit 1
    else
        if [[ -f /usr/bin/plunder ]]; then
            echo Plunder is already installed.
        else
            find / -maxdepth 4 -type f -name plunder -exec mv '{}' /usr/bin/ \;
            chmod +x /usr/bin/plunder
            echo Plunder is now installed. To use the program simply type plunder.
        fi
    fi
}


################################################################


function CLEAN_UP {

---------------------------------------------------------------------------------
#USE THE CODE BELOW IF YOU ARE USING KALI IN A VM

    if [[ `mountpoint /mnt/nfs | grep "is a mountpoint"` ]]; then
        fuser -vm &> /tmp/cleanfile
        CLEAN_PID=`tail -n 1 /tmp/cleanfile | tr -s" " | cut -d" " -f 3`
        kill -9 $CLEAN_PID
        sleep 1
        umount /mnt/nfs
        echo "Mountpoint /mnt/nfs now clean."
    fi

----------------------------------------------------------------------------------
#  USE THE CODE BELOW IF YOU ARE USING BACKTRACK 5R3 IN A VM

        
#    if [[ `mountpoint /mnt/nfs | grep "is a mountpoint"` ]]; then

        #create temperary directories for output take output from mount command 
        #parse into shares while eliminating from list normally mounted drives.
#        clear
#        echo Now cleaning mount points.
#            if [ ! -d "/tmp/clean" ]; then
#                mkdir /tmp/clean
#                mount > /tmp/clean/mount_list1
#                cut -d' ' -f 1 /tmp/clean/mount_list1 | sed '1,10d' > /tmp/clean/mount_list2
#                tac /tmp/clean/mount_list2 > /tmp/clean/mount_list1

#                    while read dir; do
#                        umount -f $dir
#                    done < /tmp/clean/mount_list1
#                rm -rf /tmp/clean
#            #this command does same actions as above just with alternate directory
#            else
#                mkdir /tmp/clean12345
#                mount > /tmp/clean12345/mount_list1
#                cut -d' ' -f 1 /tmp/clean12345/mount_list1 | sed '1,10d' > /tmp/clean12345/mount_list2
#                tac /tmp/clean12345/mount_list2 > /tmp/clean12345/mount_list1

#                    while read dir; do
#                        umount -f $dir
#                    done < /tmp/clean12345/mount_list1
#                rm -rf /tmp/clean12345
#            fi
#            rm -rf /tmp/clean
#            clear
#            echo Mount points clean.
#            echo
#    fi
}


################################################################


function ENUM_NFS {
touch $VOL_INPUT
touch $SHARES_LOG

VOL_INPUT=/home/vol_input
SHARES_LOG=/home/all_shares.log
PLUNDER_LOG=/home/plunder.log

    echo > $SHARES_LOG
    echo > $PLUNDER_LOG

    clear
    echo "Enter the target IP or full path and file name for IP list."
    echo "(ex. /home/Desktop/ip_list.txt)"
    echo
    echo -n ">>: "
    read IP_INPUT

    clear
    echo Please enter the name and full path to your keyword list.
    echo "For example (/home/keyword_list.txt)"
    echo
    echo -n ">>: " 
    read KEYWORDLIST

    clear
    echo How many directories deep do you want to search?
    echo
    echo -n ">>: " 
    read DEPTH

    clear

    #check to see if user's input to IP_INPUT IP file exists
    if [[ -f $IP_INPUT ]] ; then

        while read SERVER_IP; do

            (echo 2>&1) | tee -a $PLUNDER_LOG $SHARES_LOG
            (echo 2>&1) | tee -a $PLUNDER_LOG $SHARES_LOG
            (echo -n $(date)"    ---------------------------------------------------------" 2>&1) | tee -a $PLUNDER_LOG $SHARES_LOG
            #checks ip list to see if the host can be pinged if not skip ip
            ping -c 1 $SERVER_IP &>> $PLUNDER_LOG 
                if [[ $? = 0 ]]; then
                    (echo 2>&1) | tee -a $PLUNDER_LOG $SHARES_LOG
                    (echo "Now checking $SERVER_IP" 2>&1) | tee -a $PLUNDER_LOG $SHARES_LOG
                    (echo 2>&1) | tee -a $PLUNDER_LOG $SHARES_LOG
                    
                    #write to file nfs shares that are open to everyone
                    showmount -e $SERVER_IP &>> $SHARES_LOG
                    showmount -e $SERVER_IP | grep "(everyone)" | cut -d' ' -f 1 &> $VOL_INPUT

                        if [[ ! -d "/mnt/nfs" ]]; then
                            mkdir /mnt/nfs
                        fi

                        umount /mnt/nfs &>> $PLUNDER_LOG 

                    #while loop to mount shares, do ls -Rhal, and find world writeable files in vol0
                    while read SHARE; do
                    SHAREFOLDER_PATH=$SERVER_IP':'$SHARE
                    OUTPUT_FILE=`echo $SHAREFOLDER_PATH | tr -s ':' '_' | tr -s '/' '_'`
                    
                        (mount -o nolock $SHAREFOLDER_PATH /mnt/nfs 2>&1) | tee -a $PLUNDER_LOG &> /dev/null
                            if [[ $? = 0 ]]; then
                                (echo -n $(date)"    " 2>&1) | tee -a $PLUNDER_LOG
                                (echo "Now mounting $SHAREFOLDER_PATH" 2>&1) | tee -a $PLUNDER_LOG
                                (echo 2>&1) | tee -a $PLUNDER_LOG
                                cd /mnt/nfs &>> $PLUNDER_LOG

                                    if [[ ! -d /home/search_results ]]; then
                                        mkdir /home/search_results
                                    fi

                                    if [[ ! -d /home/search_results/$OUTPUT_FILE ]]; then
                                        mkdir /home/search_results/$OUTPUT_FILE
                                    fi

                                    while read SEARCHTERM; do
                                        (echo Now searching for $SEARCHTERM in $SHAREFOLDER_PATH 2>&1) | tee -a $PLUNDER_LOG
                                        (echo 2>&1) | tee -a $PLUNDER_LOG

                                        find / -maxdepth $DEPTH -name "$SEARCHTERM" >> /home/search_results/$OUTPUT_FILE/$SEARCHTERM
                                    done < "$KEYWORDLIST"

                                cd /mnt
                                umount /mnt/nfs &>> $PLUNDER_LOG
                                sleep 1
                            fi
                    done < $VOL_INPUT
                fi
            sleep 1
        done < $IP_INPUT
        rm $VOL_INPUT

    #check to see if user input for IP_INPUT is an IP. Regex checks for valid IP input.
    elif [[ `echo $IP_INPUT | egrep -e '^(([01]?[0-9]{1,2}|2[0-4][0-9]|25[0-4])\.){3}([01]?[0-9]{1,2}|2[0-4][0-9]|25[0-4])$'` ]] ; then

        #output to file all nfs shares that are open to everyone
        showmount -e $IP_INPUT &>> $SHARES_LOG
        showmount -e $IP_INPUT | grep "(everyone)" | cut -d' ' -f 1 &> $VOL_INPUT

            if [[ ! -d "/mnt/nfs" ]]; then
                mkdir /mnt/nfs
            fi
            
            umount /mnt/nfs &>> $PLUNDER_LOG

            #while loop to mount shares, do ls -Rhal, and find world writeable files in vol0
            while read SHARE; do
            SHAREFOLDER_PATH=$IP_INPUT':'$SHARE
            OUTPUT_FILE=`echo $SHAREFOLDER_PATH | tr -s ':' '_' | tr -s '/' '_'`

                (mount -o nolock $SHAREFOLDER_PATH /mnt/nfs 2>&1) | tee -a $PLUNDER_LOG &> /dev/null
                    if [[ $? = 0 ]]; then
                        (echo "Now mounting $SHAREFOLDER_PATH" 2>&1) | tee -a $PLUNDER_LOG
                        (echo 2>&1) | tee -a $PLUNDER_LOG
                        cd /mnt/nfs
                        
                            if [[ ! -d /home/search_results ]]; then
                                mkdir /home/search_results
                            fi

                            if [[ ! -d /home/search_results/$OUTPUT_FILE ]]; then
                                mkdir /home/search_results/$OUTPUT_FILE
                            fi

                            while read SEARCHTERM; do
                                (echo Now searching for $SEARCHTERM in $SHAREFOLDER_PATH 2>&1) | tee -a $PLUNDER_LOG
                                (echo 2>&1) | tee -a $PLUNDER_LOG

                                find / -maxdepth $DEPTH -name "$SEARCHTERM" >> /home/search_results/$OUTPUT_FILE/$SEARCHTERM
                            done < "$KEYWORDLIST"

                        cd /mnt
                        umount /mnt/nfs &>> $PLUNDER_LOG
                        sleep 1
                    fi
            done < $VOL_INPUT
            rm $VOL_INPUT
    else
        echo 
        echo The file or IP you entered does not exist or is incorrectly formatted.
        echo Please check your input and try again.
        sleep 3
    fi
}


################################################################


function MENU {
PS3=">>: "

echo -e "
\e[37m*************************************************************************\e[0m
\e[33m*                                                                       *\e[0m
\e[33m*                                PLUNDER                                *\e[0m
\e[33m*                                                                       *\e[0m
\e[33m*         This Program must be run with sudo or root privileges         *\e[0m
\e[33m*           Output files will be placed in the /home directory          *\e[0m
\e[33m*                                                                       *\e[0m
\e[37m*************************************************************************\e[0m"
	select MENU_ITEM in "Enumerate NFS" "Clean Mount Points" "Install Plunder" "Exit"; do
		case $MENU_ITEM in
			"Enumerate NFS")
			    ENUM_NFS 
			    clear ;;

			"Clean Mount Points")
			    CLEAN_UP 
			    clear ;;

			"Install Plunder")
			    PLUNDER_INSTALL 
			    clear ;;

			"Exit")
			    exit 0 ;;

			*)
			    echo An incorrect option was chosen. Please try again.
			    sleep 3
			    break ;;
		esac
		break
	done
}

while true; do
    clear
    MENU
done
