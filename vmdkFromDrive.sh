# Creates a VMDK file that points to a physical drive, allowing you to boot it in a VM

if [ -z "$1" ] || [ -z "$(ls "$1")" ]; then
    echo "Specify a drive (/dev/...)!" >&2
    exit 1
fi
if [ -z "$(which VBoxManage)" ]; then
    echo "VBoxManage command not found. Install Virtualbox!" >&2
    exit 2
fi
fname="${1////_}".vmdk
sudo VBoxManage internalcommands createrawvmdk -filename "$fname" -rawdisk "$1" &&
    sudo chown "$USER":"$USER" "$fname" &&
    sudo usermod -a -G disk "$USER" &&
    echo "VMDK created: $"fname""
