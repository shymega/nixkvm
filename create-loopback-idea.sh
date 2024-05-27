truncate -s $((1024*1024*64)) disk.img
mkfs.ext4 ./disk.img
