end=$(cat /opt/tomcat/logs/catalina.out | wc -l)
start=$(grep -n "s t a r t i n g" /opt/tomcat/logs/catalina.out|tail -n1 |cut -d":" -f1)
tail -n$(( end - start  )) /opt/tomcat/logs/catalina.out |grep -A10 ERR
