""" Read losetup input to get the device mount point. """
import sys
loop_dev = sys.stdin.readline()
loop_dev = loop_dev.split(':')[0]
print(loop_dev, end='')
