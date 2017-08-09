#!/usr/bin/env bash
set -ex

# Allow changing git branch but default to master
GITBRANCH=${GITBRANCH-master}

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

self_update() {
  # Clone and update virtual environment configurations
  if [ ! -d "$ROOT/ansible" ]; then
    git clone  -b $ansible_branch $ansible_remote $ROOT/ansible
    if [ -n "$ansible_revision" ]; then
      cd $ROOT/ansible
      git reset --hard $ansible_revision
      cd $ROOT
    fi
  else
    if [ -z "$ansible_revision" ]; then
      cd $ROOT/ansible
      git pull
      git checkout $ansible_branch
      cd $ROOT
    fi
  fi

  # Use secrets if it's defined in conf/project.yml
  # Do this for everything else than local vagrant provisioning
  if [ "$ENVIRONMENT" != "vagrant" ] && [ "$wundersecrets_remote" != "" ]; then
    # Set defaults for WunderSecrets
    export wundersecrets_path=$ROOT/secrets
    export wundersecrets_branch=${wundersecrets_branch-master}

    # Clone and update virtual environment secrets
    if [ ! -d "$wundersecrets_path" ]; then
      git clone  -b $wundersecrets_branch $wundersecrets_remote $wundersecrets_path
      if [ -n "$wundersecrets_revision" ]; then
        git -C "$wundersecrets_path" reset --hard $wundersecrets_revision
      fi
    else
      if [ -z "$wundersecrets_revision" ]; then
        git -C "$wundersecrets_path" pull
        git -C "$wundersecrets_path" checkout $wundersecrets_branch
      fi
    fi
  fi
}

# Get the folder of the provision.sh
pushd `dirname $0` > /dev/null
ROOT=`pwd -P`
popd > /dev/null

# Parse project config
PROJECTCONF=$ROOT/conf/project.yml
echo $PROJECTCONF
eval $(parse_yaml $PROJECTCONF)

self_update

if [ ! $SKIP_REQUIREMENTS ] ; then
  # Check if pip is installed
  which -a pip >> /dev/null
  if [[ $? != 0 ]] ; then
      echo "ERROR: pip is not installed! Install it first."
      echo "OSX:    $ easy_install pip"
      echo "Ubuntu: $ sudo apt-get install python-setuptools python-dev build-essential && sudo easy_install pip"
      echo "Centos: $ yum -y install python-pip"
      exit 1
  else
    # Install virtualenv
    which -a virtualenv >> /dev/null
    if [[ $? != 0 ]] ; then
      pip install virtualenv
    fi
    # Create a virtualenv for this project and use it for ansible
    if [ ! -f $ROOT/.virtualenv ]; then
      virtualenv --python=python2.7 $ROOT/ansible/.virtualenv
    fi

    # Use the virtualenv
    source $ROOT/ansible/.virtualenv/bin/activate

    # Ensure ansible & ansible library versions with pip
    if [ -f $ROOT/ansible/requirements.txt ]; then
      pip install -r $ROOT/ansible/requirements.txt --upgrade
    else
      pip install ansible
    fi
  fi
fi

# Setup&Use WunderSecrets if the additional config file exists
if [ -f $wundersecrets_path/ansible.yml ]; then
  WUNDER_SECRETS="--extra-vars=@$wundersecrets_path/ansible.yml"
else
  WUNDER_SECRETS=""
fi

# Use vault encrypted file from WunderSecrets when available
if [ "$VAULT_FILE" != "" ] && [ -f $wundersecrets_path/vault.yml ]; then
  WUNDER_SECRETS="$WUNDER_SECRETS --extra-vars=@$wundersecrets_path/vault.yml"
fi

ansible-playbook $WUNDER_SECRETS "$@"
