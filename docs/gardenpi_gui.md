**GardenPi GUI Implementation**

***Overview***

GardenPi GUI implementation is based on Grafana, Prometheus Node Exporter for arm v6 architecture and Prometheus Server. To screpe gardenlightsctrl.service Prometheus textfile data collector is used. 

![alt text](https://prometheus.io/assets/architecture.png)

Due to current bug not allowing to change Grafana's TCP port number to 80 using grafana.ini file, port redirection from port 80 to 3000 using iptables has been configured instead.

***Prometheus Installation and Configuration***

***Grafana Installation and Configuration***

***Grafana Dashboard Implementation***

***IP Tables Configuration***



