#!/bin/bash

source cfg

JEL_UID=$DEV_UID
JEL_URL=$DEV_URL
JEL_PWD=$DEV_PWD

while [ "$1" != "" ]; do
    case $1 in
        prod )          JEL_UID=$PROD_UID
                        JEL_URL=$PROD_URL
                        JEL_PWD=$PROD_PWD
                        ;;
        -e | --env )    shift
                        ENVNAME=$1
                        ;;
        -u | --user )   shift
                        SIGNASUSER=$1
                        ;;
        * )             echo "args : \n-e envname \nprod if prod env"
                        exit 1
    esac
    shift
done

db=""
ha=""
ja=""
nodes=$(./get_envs_containers.py $JEL_PWD $ENVNAME $JEL_URL $MAIL $SIGNASUSER)

for node in $nodes
do
    nodeId=${node:2}
    if [ ${node:0:2} == "cp" ] || [ ${node:0:2} == "pr" ]; then
        ja="$ja $nodeId"
    elif [ ${node:0:2} == "sq" ]; then
        db="$db $nodeId"
    elif [ ${node:0:2} == "bl" ]; then
        ha="$ha $nodeId"
    fi
done

dbNodesCount=$(echo $db|wc -w)
if [[ $dbNodesCount -gt 1 ]]; then
    nodeId=$(echo $db|cut -d' ' -f1)
    echo -n "Check database cluster health on node $nodeId ...."
    size_ok=$(ssh $nodeId-$JEL_UID@gate.$JEL_URL -p 3022 "mysql -e \"show global status like 'wsrep_cluster_size';\"|grep $dbNodesCount")
    if [ -z "$size_ok" ]; then
         echo -e "[\e[91mKO\e[39m] "
    else
        echo -e "[\e[32mOK\e[39m]"
    fi
fi
for nodeId in $ja
do
    running=$(ssh $nodeId-$JEL_UID@gate.$JEL_URL -p 3022 "sudo service tomcat status|grep -v not")
    echo -n "[$nodeId]  Check if tomcat is running....."
    if [ -z "$running" ]; then
        echo -e "[\e[91mKO\e[39m] "
    else
        echo -e "[\e[32mOK\e[39m]"
        echo -n "[$nodeId]  Check if tomcat is ready....."
        is_ready=$(ssh -T $nodeId-$JEL_UID@gate.$JEL_URL -p 3022 < is_tomcat_ready.sh)
        if [ -z "$is_ready" ]; then
            echo -e "[\e[91mKO\e[39m] "
        else
            echo -e "[\e[32mOK\e[39m]"
        fi
    fi
    echo -n "[$nodeId]  Check if catalina.out contains errors....."
    errors=$(ssh -T $nodeId-$JEL_UID@gate.$JEL_URL -p 3022 < check_catalina_logs.sh)
    if [ -z "$errors" ]; then
        echo -e "[\e[32mOK\e[39m]"
    else
        echo -e "[\e[91mKO\e[39m] "
        echo $errors | awk '{ print substr($0, 1, 600) }'
    fi
    echo -n "[$nodeId]  Check HTTP access....."
    http_check=$(ssh $nodeId-$JEL_UID@gate.$JEL_URL -p 3022 "curl -IL -s -m 1 127.0.0.1 |head -n 1 |cut -d$' ' -f2")
    if [[ $http_check -eq 401 ]]; then
        echo -e "[\e[32mOK\e[39m]"
    else
        echo -e "[\e[91mKO\e[39m] Returned $http_check"
    fi

done
