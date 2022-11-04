#!/bin/bash
#Tested on Ubuntu 18.04 on GCP


vncPassword=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/vncpass -H "Metadata-Flavor: Google")
#username=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/linuxuser -H "Metadata-Flavor: Google")
username="gameuser"
WEBSOCKIFY_VERSION=0.8.0
NOVNC_VERSION=1.0.0-beta



if [ ! -f "/etc/notfirstboot" ]
then
	wget -O /usr/bin/cloudgamingstart.sh https://raw.githubusercontent.com/komurlu/LinuxCloudGaming/testing/setupInstance.sh
	chmod +x /usr/bin/cloudgamingstart.sh
	
	dpkg --add-architecture i386
	curl -O https://storage.googleapis.com/nvidia-drivers-us-public/GRID/GRID8.0/NVIDIA-Linux-x86_64-418.70-grid.run &

	apt-get update
	apt-get install -y dialog pulseaudio  libsdl2-image-2.0-0 xserver-xorg-core \
		x11-apps x11-utils mesa-utils xterm xfonts-base tigervnc-common  \
		x11-xserver-utils  x11vnc icewm steam-installer gcc make python pkg-config-aarch64-linux-gnu 
	
	bash NVIDIA-Linux-x86_64-418.70-grid.run -a -q -N --ui=none
	nvidia-xconfig --virtual=1280x720


	#We'll use these non-OS disks as Steam game folders.
	#These have to be added as Steam Library Folders on Steam GUI.
	#TODO can we add these with a script?
	mkdir /mnt/game

	#persistent disks of GCP
	if [ -e "/dev/sdb" ]
	then
		if [[ $(lsblk /dev/sdb -no fstype) != "ext4" ]]
		then
			mkfs.ext4 /dev/sdb
		fi
  
		mount /dev/sdb /mnt/game
		chown -R $username:$username /mnt/game
		echo "/dev/sdb     /mnt/game    ext4    defaults,nofail    0 0" >> /etc/fstab
	fi
	#Local SSD of GCP
	if [ -e "/dev/nvme0n1" ]
	then
		if [[ $(lsblk /dev/nvme0n1 -no fstype) != "ext4" ]]
		then
			mkfs.ext4 /dev/nvme0n1
		fi
	
		mount /dev/nvme0n1 /mnt/game
		chown -R $username:$username /mnt/game
		echo "/dev/nvme0n1     /mnt/game    ext4    defaults,nofail    0 0" >> /etc/fstab
	fi
	
	#Download GloriousEgroll
	runuser -l $username -c 'wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/4.21-GE-2/Proton-4.21-GE-2.tar.gz'
	runuser -l $username -c "mkdir /home/$username/.steam"
	runuser -l $username -c "mkdir /home/$username/.steam/compatibilitytools.d/"
	runuser -l $username -c "tar -C /home/$username/.steam/compatibilitytools.d/ -zxvf Proton-4.21-GE-2.tar.gz"

	#Setup VNC password for user
	runuser -l $username -c "echo -e '$vncPassword\n$vncPassword\nn' | vncpasswd"

	#this is for dummy Xorg screen. Relevant xorg.conf and xserver-xorg-video-dummy needed
	#nohup /usr/bin/Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile ./10.log -config /root/xorg.conf :1&
	
	curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt
	curl -fsSL https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzf - -C /opt
	mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC
	mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/websockify
	ln -s /opt/noVNC/vnc_lite.html /opt/noVNC/index.html
	cd /opt/websockify && make
	#make self signed certificate
	runuser -l $username -c "openssl req -new -x509 -days 365 -nodes -subj '/C=TR/emailAddress=a/ST=a/L=a/O=a/OU=a/CN=a' -out /home/$username/self.pem -keyout /home/$username/self.pem"
	
	(
	cat <<-'EOF'
		[Unit]
		Description=Desktop Steam and VNC
		Requires=multi-user.target
		After=multi-user.target
		AllowIsolate=yes
	EOF
	)> /etc/systemd/system/custom.target
	
	(
	cat <<-'EOF'
		[Unit]
		Description=Start Desktop Steam VNC
		After=multi-user.target

		[Service]
		Type=simple
		ExecStart=/usr/bin/cloudgamingstart.sh

		[Install]
		WantedBy=custom.target
	EOF
	)> /etc/systemd/system/cloudgaming.service
	
	mkdir /etc/systemd/system/custom.target.wants
	ln -s /etc/systemd/system/cloudgaming.service /etc/systemd/system/custom.target.wants/cloudgaming.service
	systemctl set-default custom.target
	
	touch /etc/notfirstboot
fi
#END notfirstboot
	
#Below will run both at first creation and after reboot



#No need to run x11vnc because websockify and novnc will
#nohup x11vnc -loop -forever -repeat -display :0 -rfbport 5901&

nohup Xorg &
nohup runuser -l $username -c 'DISPLAY=:0 icewm-session'&
nohup runuser -l $username -c 'DISPLAY=:0 steam'&
nohup runuser -l $username -c '/opt/websockify/run 5901 --cert=./self.pem --ssl-only --web=/opt/noVNC --wrap-mode=ignore -- x11vnc  -usepw -display :0 -rfbport 5901 -loop -forever -repeat -noxdamage'&



