#!/bin/bash

#######################################################
# BASIC CONFIGURATION
#######################################################
if [ "" == "${DO_CONFIGS}" ]; then
    DO_CONFIGS=true
fi

#Wrap bash argument with double quotes to pass them into python later
CLI_ARGS=""
for i in "$@"
do
  #Only wrap arguments with space
  if [[ "$i" == *" "* ]]; then
    i="\"$i\""
  fi
  CLI_ARGS="$CLI_ARGS $i"
done

export ALLOWED_OPERATIONS="${ANSIBLE_SCRIPTS}"
if [ "" != "${PYTHON_SCRIPTS}" ]; then
    export ALLOWED_OPERATIONS="${ALLOWED_OPERATIONS},${PYTHON_SCRIPTS}"
fi
if [ "" != "${SHELL_SCRIPTS}" ]; then
    export ALLOWED_OPERATIONS="${ALLOWED_OPERATIONS},${SHELL_SCRIPTS}"
fi
export PROG=$0  # FOR ARG PARSING HELP OUTPUT

function parse_args()
{
    ARGSMODE=$1
    OUTPUT=$(eval "python $HELPER_SCRIPTS_FOLDER/parse_args.py $STACK_TYPE $DO_CONFIGS $ARGSMODE $CLI_ARGS")
    if (echo "$OUTPUT" | grep -q "PARSE_SUCCESS=YES"); then
        eval "$OUTPUT"
        export OPERATION=${OPERATION}
        PARSED=1
    else
        RETVAL=$?
        echo -e "$OUTPUT"
        exit $RETVAL
    fi
}

function run_setup()
{
    echo Installing dependencies...
    source ${INIT_DIR}/init_setup.sh
}

function normal_handling()
{
    parse_args full
}

#######################################################
# PARSE ARGUMENTS TO GET OPERATION ONLY
#######################################################
parse_args operation_only

#######################################################
# HANDLE PYTHON SCRIPTS
#######################################################
if echo ",${PYTHON_SCRIPTS}," | grep -q ",${OPERATION},"; then
    if type -t special_handling > /dev/null; then
        special_handling $OPERATION
    fi
    run_setup
    if [ "${COMMAND_TO_RUN}" != "" ]; then
        python ${COMMAND_TO_RUN} ${CLI_ARGS} ${EXTRA_PLAYBOOK_ARGS}|| exit $?
    elif [ -f "${OPERATION}.py" ] && [ true == "${DO_CONFIGS}" ]; then
        python ${OPERATION}.py ${STACK_TYPE} ${CLI_ARGS} ${EXTRA_PLAYBOOK_ARGS}|| exit $?
    elif [ -f "${OPERATION}.py" ]; then
        python ${OPERATION}.py ${CLI_ARGS} ${EXTRA_PLAYBOOK_ARGS}|| exit $?
    else
        python $HELPER_SCRIPTS_FOLDER/stack_${OPERATION}.py ${STACK_TYPE} ${CLI_ARGS} ${EXTRA_PLAYBOOK_ARGS}|| exit $?
    fi
fi

#######################################################
# HANDLE SHELL SCRIPTS
#######################################################
if echo ",${SHELL_SCRIPTS}," | grep -q ",${OPERATION},"; then
    if type -t special_handling > /dev/null; then
        special_handling $OPERATION
    fi
    if [ $PARSED -eq 0 ]; then
        normal_handling $OPERATION
    fi
    
    source ${OPERATION}.sh || exit $?

fi

#######################################################
# HANDLE ANSIBLE SCRIPTS
#######################################################
if echo ",${ANSIBLE_SCRIPTS}," | grep -q ",${OPERATION},"; then
    PARSED=0
    if type -t special_handling > /dev/null; then
        special_handling $OPERATION
    fi
    if [ $PARSED -eq 0 ]; then
        normal_handling $OPERATION
    fi

    run_setup
    echo Running playbook...
    PLAYBOOK="${OPERATION}.yml"

    export ANSIBLE_SSH_CONTROL_PATH="~/.ansible/cp/${STACK_TYPE::1}-%%C"

    if [ true != "${DO_CONFIGS}" ]; then
        ANSIBLE_CMD="ansible-playbook ${PLAYBOOK} -i inventory.yml ${EXTRA_PLAYBOOK_ARGS} ${UNPARSED}"
    else
        ANSIBLE_CMD="ansible-playbook ${PLAYBOOK} -i inventory.yml -e \"@${STACK_TYPE}s/${STACK}.yml\" -e \"config_name=${STACK}\" ${EXTRA_PLAYBOOK_ARGS} ${UNPARSED}"
    fi

    #######################################################
    # VALIDATION THAT THE 'CONFIG'_NAME MATCHES THE FILENAME
    #######################################################
    if [ -d "${SETUP_DIR}/${STACK_TYPE}s" ]; then
        CONFIGNAME="$(grep -s ${STACK_TYPE}_name ${STACK_TYPE}s/${STACK}.yml | awk '{print $2}')"
        if [ "${CONFIGNAME}" != "${STACK}" ]; then
            echo -e "\e[31mERROR: The ${STACK_TYPE}_name variable defined in the config file of your (${STACK}) does not match the (${CONFIGNAME}) within the config."
            exit 1
        fi
    fi

    echo "$ANSIBLE_CMD"
    echo
    eval "$ANSIBLE_CMD" || exit $?
fi

#######################################################
# EXECUTE POST PROCESSING
#######################################################
if type -t post_processing > /dev/null; then
    post_processing $OPERATION $STACK
fi
