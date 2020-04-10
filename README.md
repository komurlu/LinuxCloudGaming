# Linux Cloud Gaming

This is a setup script for Linux cloud gaming instance on GCP. It should be setup as a startup script.

Some firewall settings needed for Steam Remoteplay and Vnc over web. Also setup your keys for ssh login if you need it.This REAME needs more updating.

Allow HTTPS (tcp 443) and following ports for Steam Remote Play:
```
tcp:27036
tcp:27037
udp:27031
udp:27036
```

<b>USAGE</b>

Add this as startup script to your instance metadata:

```bash
wget -O - https://raw.githubusercontent.com/komurlu/LinuxCloudGaming/master/setupInstance.sh | bash
```
Add following as custom metadata (without semicolons)
```
vncpass: "A password you'll chose for Remote Desktoping to your VM over the web"
linuxuser: "Your local username for the VM"
```
![alt text](https://raw.githubusercontent.com/komurlu/LinuxCloudGaming/master/images/metadata.JPG)

<b>Disks:</b> Attach an additional disk when creating your instance for installing your games. You can select SSD/Standart persistent disk or local SSD scratch disk. (Local SSD will be terminated if you delete your instance, your game download will be lost) This disk will be mounted under `/mnt/game`.

On Steam GUI, you should add a Library folder, under `/mnt/game`

It takes approximately 5 minutes for script to complete. After that connect your VM using this address https://VM-IPAddress:5901/

Instance template is as follows:
```json
{
  "creationTimestamp": "2020-04-10Txxxxxx",
  "description": "",
  "id": "862409xxxxxx",
  "kind": "compute#instanceTemplate",
  "name": "script-gpu-euro-ubuntu-2",
  "properties": {
    "scheduling": {
      "onHostMaintenance": "TERMINATE",
      "automaticRestart": false,
      "preemptible": true
    },
    "tags": {
      "items": [
        "steam",
        "http-server",
        "https-server"
      ]
    },
    "disks": [
      {
        "type": "PERSISTENT",
        "deviceName": "script-gpu-euro-ubuntu-2",
        "autoDelete": true,
        "index": 0.0,
        "boot": true,
        "kind": "compute#attachedDisk",
        "mode": "READ_WRITE",
        "initializeParams": {
          "sourceImage": "projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20200218",
          "diskType": "pd-standard",
          "diskSizeGb": "10"
        }
      },
      {
        "type": "SCRATCH",
        "deviceName": "local-ssd-0",
        "autoDelete": true,
        "index": 1.0,
        "kind": "compute#attachedDisk",
        "mode": "READ_WRITE",
        "initializeParams": {
          "diskType": "local-ssd"
        },
        "interface": "NVME"
      }
    ],
    "networkInterfaces": [
      {
        "network": "projects/YourProject/global/networks/default",
        "accessConfigs": [
          {
            "name": "External NAT",
            "type": "ONE_TO_ONE_NAT",
            "kind": "compute#accessConfig",
            "networkTier": "PREMIUM"
          }
        ],
        "kind": "compute#networkInterface"
      }
    ],
    "reservationAffinity": {
      "consumeReservationType": "ANY_RESERVATION"
    },
    "canIpForward": false,
    "machineType": "n1-standard-8",
    "metadata": {
      "fingerprint": "xxxxxx",
      "kind": "compute#metadata",
      "items": [
        {
          "value": "yourpass",
          "key": "vncpass"
        },
        {
          "value": youruser",
          "key": "linuxuser"
        },
        {
          "value": "#!/bin/bash\nwget -O - https://raw.githubusercontent.com/komurlu/LinuxCloudGaming/master/setupInstance.sh | bash",
          "key": "startup-script"
        }
      ]
    },
    "shieldedVmConfig": {
      "enableSecureBoot": false,
      "enableVtpm": true,
      "enableIntegrityMonitoring": true
    },
    "shieldedInstanceConfig": {
      "enableSecureBoot": false,
      "enableVtpm": true,
      "enableIntegrityMonitoring": true
    },
    "serviceAccounts": [
      {
        "email": "sometingsomething@developer.gserviceaccount.com",
        "scopes": [
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/logging.write",
          "https://www.googleapis.com/auth/monitoring.write",
          "https://www.googleapis.com/auth/servicecontrol",
          "https://www.googleapis.com/auth/service.management.readonly",
          "https://www.googleapis.com/auth/trace.append"
        ]
      }
    ],
    "guestAccelerators": [
      {
        "acceleratorCount": 1.0,
        "acceleratorType": "nvidia-tesla-t4"
      }
    ],
    "displayDevice": {
      "enableDisplay": false
    }
  },
  "selfLink": "projects/YourProject/global/instanceTemplates/script-gpu-euro-ubuntu-2"
}
```
