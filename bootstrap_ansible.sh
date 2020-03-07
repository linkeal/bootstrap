#!/bin/bash -e


get_or_create_public_key() {

FILE=$HOME/.ssh/id_rsa.pub
if test -f "$FILE"; then
    echo "$FILE exist"
else 
	echo "Generating public key into file $FILE"
	ssh-keygen -y -f "$SSH_DIR/id_rsa" > "$SSH_DIR/id_rsa.pub"
fi
}


show_public_key_for_github() {

FILE=$HOME/.ssh/id_rsa.pub
echo "Please add the following public key to Github"
FINGERPRINT=$(ssh-keygen -E md5 -lf $FILE)
echo "Fingerprint: $FINGERPRINT"
echo "***********"
cat "$FILE"
echo "***********"

read -r -p "Added to Github (y/n)? " answer
case ${answer:0:1} in
	y|Y )
		return
	;;
	* )
		show_public_key_for_github
	;;
esac
}


create_or_save_private_key () {

PS3='Please enter your choice: '
options=("1: Provide private key" "2: Create private key")
select opt in "${options[@]}"
do
    case $opt in
        "1: Provide private key")
			SSH_DIR=$HOME/.ssh
			echo "Please provide your private key"
			echo "Please press any key to continue. Vi will open up where you can paste your private key"
			${VISUAL:-${EDITOR:-vi}} "$SSH_DIR/id_rsa"
			chmod 600 "$SSH_DIR/id_rsa"
			get_or_create_public_key
			break
            ;;
        "2: Create private key")
			ssh-keygen -b 4096 -t rsa -f "$HOME"/.ssh/id_rsa -q -N ""
			break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
}

VENV_DIR=${VENV_DIR:=$HOME/venv/ansible}  # If variable not set or null, set it to default. 

echo "Install necessary packages"
sudo apt-get install -y python3 virtualenv git

echo "Install ansible in virtualenv under directory $VENV_DIR"
mkdir -p $(dirname "${VENV_DIR}")
virtualenv -p python3 "$VENV_DIR"
source "${VENV_DIR}/bin/activate"
pip install ansible


FILE=$HOME/.ssh/id_rsa
if test -f "$FILE"; then
    echo "$FILE exist"
	read -r -p "Do you want to overwrite the existing private key saved under $FILE? (y/n)?" answer
	case ${answer:0:1} in
		y|Y )
			create_or_save_private_key
			break
		;;
		* )
			break
		;;
	esac
else
	echo "$FILE does not exist."
	create_or_save_private_key
fi

get_or_create_public_key
show_public_key_for_github


mkdir -p "$HOME"/git
cd "$HOME"/git
git clone git@github.com:linkeal/ansible.git
cd ansible

ansible-galaxy install -r requirements.yml

echo "Ansible repo in $HOME/git/ansible is ready to use"
echo "You can run further setups via ansible-playbook setup.yml"
