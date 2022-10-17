# GardenPi GUI Implementation

<https://andrzejmazur2021.atlassian.net/wiki/spaces/~5ea827ff021ae30ba8e9fd23/pages/235470856/GardenPi+GUI+Implementation>

* * *

GardenPi GUI implementation is based on Grafana, Prometheus Node Exporter for arm v6 architecture and Prometheus Server. To screpe gardenlightsctrl.service Prometheus textfile data collector is used.

![](https://andrzejmazur2021.atlassian.net/wiki/download/thumbnails/235470856/image-20221016-131643.png?version=1&modificationDate=1665926207300&cacheVersion=1&api=v2&width=442&height=265)

Due to current bug not allowing to change Grafana's TCP port number to 80 using grafana.ini file, port redirection from port 80 to 3000 using iptables has been configured instead.

## Prometheus Server Installation and Configuration

Check version of your arm architecture with: `cat /proc/cpuinfo`

```bash
cat cat /proc/cpuinfo
cat: cat: No such file or directory
processor	: 0
model name	: ARMv6-compatible processor rev 7 (v6l)
BogoMIPS	: 997.08
Features	: half thumb fastmult vfp edsp java tls 
CPU implementer	: 0x41
CPU architecture: 7
CPU variant	: 0x0
CPU part	: 0xb76
CPU revision	: 7

Hardware	: BCM2835
Revision	: 9000c1
Serial		: 00000000148e772f
Model		: Raspberry Pi Zero W Rev 1.1
```

In case of Pi Zero this is ARMv6.

Download Prometheus Server for your architecture from: [https://prometheus.io/download/](https://prometheus.io/download/) to your host machine, then copy it to your Pi Zero platform/PiGarden controller:

`scp /home/pi/Downloads/prometheus-2.39.1.linux-armv6.tar.gz pi@gardenpi.local:/home/pi`

Update all packages installed on the platform:

```bash
sudo apt update
apt list --upgradable
sudo apt upgrade
sudo shutdown -r now 
```

Extract the binaries outside of the archive you downloaded, move extracted directory to target location named `~/prometheus` and delete gz archive:

```bash
tar xfz prometheus-2.39.1.linux-armv6.tar.gz
mv prometheus-2.39.1.linux-armv6 prometheus
rm prometheus-2.39.1.linux-armv6.tar.gz
```

Create prometheus service file:

`sudo nano /etc/systemd/system/prometheus.service`

with following contents:

```bash
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=pi
Restart=on-failure

ExecStart=/home/pi/prometheus/prometheus \
  --config.file=/home/pi/prometheus/prometheus.yml \
  --storage.tsdb.path=/home/pi/prometheus/data

[Install]
WantedBy=multi-user.target
```

Upon starting up, it will run the Prometheus executable located at “`/home/pi/prometheus/prometheus`“.

We pass in both the config file location and a storage location for the database that the monitoring software requires.

If you ever need to modify the config file, you can find it at “`/home/pi/prometheus/prometheus.yml`“.

Make prometheus service starting when Pi boots, then start the service manually and check its status:

```bash
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
```

Test prometheus service installation using curl:

## Prometheus Node Exporter Installation and Configuration

This time we use apt package installer to install Prometheus Node Exporter package:

```bash
sudo apt-get install prometheus-node-exporter
apt list --upgradable
sudo apt upgrade
```

Prometheus Node Exporter service file can be found at:

`/lib/systemd/system/prometheus-node-exporter.service`

Prometheus by default listens on port 9090, but we are interested in metricises from node exporter, which broadcasts data it scrapas on port 9100. That is why we need to reconfigure port number Prometheus Sever listens to and set it to 9100. This is done by the following modification of `~/prometheus/prometheus.yml` file in the following three areas:

```bash
global:
  #scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  #evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.

  scrape_interval: 3s # Set the scrape interval to every 3 seconds. Default is every 1 minute.
  evaluation_interval: 3s # Evaluate rules every 3 seconds. The default is every 1 minute.

```

```bash
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "raspi"
```

```bash
    static_configs:
      #- targets: ["localhost:9090"]
      - targets: ["localhost:9100"]
```

To confirm that Prometheus Server is now receiving metrics' from Node Exporter execute the following command, which shall received cpu related metrics’:

```bash
curl http://localhost:9100/metrics | grep node_thermal_zone_temp
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  130k    0  130k    0     # HELP node_thermal_zone_temp Zone temperature in Celsius
0 # TYPE node_thermal_zone_temp gauge
 node_thermal_zone_temp{type="cpu-thermal",zone="0"} 64.27
 529k      0 --:--:-- --:--:-- --:--:--  529k
```

If port Prometheus Server listens to is not changed correctly then no node\_ metrics' will be possible to fetch with curl…

Since we will need to report some gardenpi specific metrics' generated by `gardenlightsctrl.service` lets use for it textfile data collector of Prometheus Node Exporter. This collector is enabled by default and it scrapes all metrics' from files with .prom extension, which are located in the following directory:

`/var/lib/prometheus/node-exporter/`

More information regarding this data collector is available at: [https://github.com/prometheus/node\_exporter](https://github.com/prometheus/node_exporter)

To store metrics' specific to gardenpi lets create the following .prom file and make a symbolic link to it from `/var/lib/prometheus/node-exporter/` directory:

```bash
touch /home/pi/PyScripts/SolarCalc/solarcalc.prom
sudo ln ./solarcalc.prom /var/lib/prometheus/node-exporter/gardenpi.prom
```

Update contents of created solarcalc.prom file with simple test matrics:

`nano /home/pi/PyScripts/SolarCalc/solarcalc.prom`

```bash
# HELP gardenpi_lights_state Lights on/off indicator.
# TYPE gardenpi_lights_state gauge
gardenpi_lights_state 1
```

To verify that gardenpi metrics' are exposed to Prometheus Server:

```bash
ls -al /var/lib/prometheus/node-exporter/
total 12
drwxr-xr-x 2 root       root       4096 Oct 16 21:43 .
drwxr-xr-x 3 prometheus prometheus 4096 Oct 16 17:43 ..
-rw-r--r-- 1 root       root        397 Oct 16 21:43 apt.prom
-rw-r--r-- 2 pi         pi            0 Oct 16 21:41 gardenpi.prom
```

```bash
curl http://localhost:9100/metrics | grep gardenpi
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3944    0  3944    0     0   2409      0 --:--:--  0:00:01 --:--:--  2410# HELP gardenpi_lights_state Lights on/off indicator.
# TYPE gardenpi_lights_state gauge
gardenpi_lights_state 1
node_textfile_mtime_seconds{file="gardenpi.prom"} 1.66594986e+09
100  115k    0  115k    0     0  67378      0 --:--:--  0:00:01 --:--:-- 67378
node_uname_info{domainname="(none)",machine="armv6l",nodename="gardenpi",release="5.15.61+",sysname="Linux",version="#1579 Fri Aug 26 11:08:59 BST 2022"} 1
```

## Grafana Installation (RB PI4)

Add the APT key used to authenticate packages:

`wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -`

Add the Grafana APT repository:

`echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list`

Install Grafana:

```bash
sudo apt-get update
sudo apt-get install -y grafana
```

Enable the Grafana server so it always starts after gardenpi is booted:

`sudo systemctl enable grafana-server`

Start the Grafana server:

```bash
sudo systemctl start grafana-server
sudo systemctl status grafana-server
```

Grafana is now running on the machine and is accessible from any device on the local network. it is accessible from host machine browser under the address: `gardenpi.local:3000`

Default grafana’s login credentials to be used during first login are: user: admin, password: admin

## Grafana Installation (RB PI Zero)

Uninstall grafana package installed with apt package manager (with all config files):

```bash
sudo apt purge grafana
sudo rm -rf /etc/grafana
```

Execute installation procedure from grafana web page for arm6 version: [https://grafana.com/grafana/download?platform=arm](https://grafana.com/grafana/download?platform=arm)

```bash
sudo apt-get install -y adduser libfontconfig1
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-rpi_9.2.0_armhf.deb
sudo dpkg -i grafana-enterprise-rpi_9.2.0_armhf.deb
```

Enable the Grafana server so it always starts after gardenpi is booted:

```bash
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
```

Start the Grafana server:

```bash
sudo systemctl start grafana-server
sudo systemctl status grafana-server
```

Grafana is now running on the machine and is accessible from any device on the local network. it is accessible from host machine browser under the address: `gardenpi.local:3000`

Default grafana’s login credentials to be used during first login are: user: admin, password: admin

At first login password has to be changed for admin user. new password is set to raspberry.

## Grafana Configuration

Due to current bug not allowing to change Grafana's TCP port number to 80 using grafana.ini file, port redirection from port 80 to 3000 using iptables has been configured instead.

iptables rules allowing grafana gui to be reached from browser on http port 80 following rules needs to be added:

redirection from outside world:  
`sudo iptables -A PREROUTING -t nat -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 3000`

redirection on the same machine:  
`sudo iptables -t nat -A OUTPUT -o lo -p tcp --dport 80 -j REDIRECT --to-port 3000`

In order to save new iptables rules `iptables-persistent` package has to be installed:

`sudo apt-get install iptables-persistent`

To list currently defined iptables rules for ipv4:

`nano /etc/iptables/rules.v4`

Content of above file after implementing port 80 to 3000 redirection:

```bash
# Generated by iptables-save v1.8.7 on Sun Oct 16 23:55:46 2022
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i wlan0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3000
-A OUTPUT -o lo -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3000
COMMIT
# Completed on Sun Oct 16 23:55:46 2022
```

After adding new rules either directly to the file abbove `COMMIT` line or through `iptables` command. The new rules set can be saved with:

```bash
sudo su -
root@raspberrypi:~# sudo iptables-save > /etc/iptables/rules.v4
root@raspberrypi:~# exit
```

Login to grafana’s gui:

```bash
http://gardenpi.local
user: admin
password: raspberry
```

Go to admin panel, click bottom left shield icon and define pi user with no admin privileges:

```bash
user: pi
password: raspberry
```

Go to configuration, data sources and select Prometheus.

From Prometheus Datasource configuration panel the only place to make an adjustment is Prometheus server address:

![](https://andrzejmazur2021.atlassian.net/wiki/download/thumbnails/235470856/image-20221017-071412.png?version=1&modificationDate=1665990855361&cacheVersion=1&api=v2&width=442&height=276)

Go to Dashboards, new, import and select to import from json file. Point at `./gui/GardenPiController.json`

Set imported gui as favourite (star in top left section of the gui)

Got to Configuration, Preferences and set home dashboard to GardenPi/GardenPi Controller:

![](https://andrzejmazur2021.atlassian.net/wiki/download/thumbnails/235470856/image-20221017-201815.png?version=1&modificationDate=1666037898769&cacheVersion=1&api=v2&width=453&height=313)

## References

[https://prometheus.io/docs/introduction/overview/](https://prometheus.io/docs/introduction/overview/)

[https://pimylifeup.com/raspberry-pi-prometheus/](https://pimylifeup.com/raspberry-pi-prometheus/)

[https://github.com/prometheus/node\_exporter](https://github.com/prometheus/node_exporter)

[https://grafana.com/tutorials/install-grafana-on-raspberry-pi/](https://grafana.com/tutorials/install-grafana-on-raspberry-pi/)

[https://grafana.com/grafana/download?platform=arm](https://grafana.com/grafana/download?platform=arm)

[https://blog.mxard.com/persistent-iptables-on-raspberry-pi-raspbian](https://blog.mxard.com/persistent-iptables-on-raspberry-pi-raspbian)