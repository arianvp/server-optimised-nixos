# !/bin/sh
# Helper to show contents of initrd
zcat $1 | cpio -t | less
