#!/bin/sh
read n

for((i=1;i<=n;i++))
do
ip netns add ns$i
ip link add vns$i type veth peer name vbr$i
ip link set vns$i netns ns$i
done

for((i=1;i<=n;i++))
do
ip netns exec ns$i ip addr add 192.168.0.$i/16 dev vns$i
ip netns exec ns$i ip link set dev vns$i up
ip netns exec ns$i ip link set dev lo up
done

ovs-vsctl add-br br
ip addr add 192.168.0.254/16 dev br
ip link set dev br up
ip link set dev ovs-system up
ip addr add 192.168.0.254/16 dev br
ip link set dev ovs-system up

for((i=1;i<=n;i++))
do
ovs-vsctl add-port br vbr$i
ip link set dev vbr$i up
done


for((i=0;i<=n;i++))
do
ip netns exec ns$i ip route add default via 192.168.0.254
iptables -t nat -A POSTROUTING -s 192.168.0.$i/16 -j  MASQUERADE
sysctl -w net.ipv4.ip_forward=1
done

for((i=1;i<=n;i++))
do
ip netns exec ns$i ping -c 1 8.8.8.8
done

for((i=1;i<=n;i++))
do
ip netns del ns$i
ovs-vsctl del-br br
done

