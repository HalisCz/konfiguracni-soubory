ssh-copy-id-exchange() {
	OLDKEY="/home/halis/.ssh/id_rsa-eleanor"
	OLDKEY_PUB="/home/halis/.ssh/id_rsa-eleanor.pub"
	NEWKEY="/home/halis/.ssh/id_rsa-XPS"
	NEWKEY_PUB="/home/halis/.ssh/id_rsa-XPS.pub"

	echo "Trying login with new key"
	ssh -i $NEWKEY -o "PreferredAuthentications=publickey" $1 "true"
	#exit if it successed
	if [ $? -eq "0" ]; then
		echo "New key is on the server, nothing to do"
	#try old key if it did not work
	else
		echo "New key is not on the server"
		#try to login with old key
		ssh -i $OLDKEY -o "PreferredAuthentications=publickey" $1 "true"
		#if it succeed, grep new key in authorized_keys
		if [ $? -eq "0" ]; then
			echo "Old key is on the server, proceeding"
			ssh -i $OLDKEY -o "PreferredAuthentications=publickey" $1 "grep '$(cat $NEWKEY_PUB)' ~/.ssh/authorized_keys"
			if [ $? -eq "0" ]; then
				echo "Weird, new key is in the authorized_keys"
			#if not found, add it
			else
				cat $NEWKEY_PUB | ssh -i $OLDKEY -o "PreferredAuthentications=publickey" $1 "cat >> .ssh/authorized_keys" && \
				echo "New key added to authorized_keys" && \
				#try login with new key
				ssh -i $NEWKEY -o "PreferredAuthentications=publickey" $1 "true" && \
				echo "Succesfully loged in with new key. My job here is done."
			fi
		#If it did not succeed, end.
		else
			echo "Old key is not on the server"
		fi
	fi
}
