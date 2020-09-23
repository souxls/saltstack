net.netfilter.nf_conntrack_max:
  sysctl.present:
    - value: 1048576
# Limit of socket listen() backlog, Defaults to 128
net.core.somaxconn:
  sysctl.present:
    - value: 81920
# maximum receive socket buffer size (8Mbytes)
net.core.rmem_max:
  sysctl.present:
    - value: 8388608

# maximum send socket buffer size (8Mbytes)
net.core.wmem_max:
  sysctl.present:
    - value: 8388608

# default setting in bytes of the socket receive buffer (64Kbytes)
net.core.rmem_default:
  sysctl.present:
    - value: 65536

# default setting in bytes of the socket send buffer (64Kbytes)
net.core.wmem_default:
  sysctl.present:
  - value: 65536

net.ipv4.tcp_rmem:
  sysctl.present:
    - value: 4096 87380 8388608
net.ipv4.tcp_wmem:
  sysctl.present:
    - value: 4096 65536 8388608
net.ipv4.tcp_mem:
  sysctl.present:
    - value: 8388608 8388608 8388608

# Time to hold socket in state FIN-WAIT-2
# If we send FIN actively (we are in FIN-WAIT-1), 
# then receive the peer's ACK (we are in FIN-WAIT-2),
# but not receive the peer's FIN (we stay in FIN-WAIT-2).
# Default value is 60sec
net.ipv4.tcp_fin_timeout:
  sysctl.present:
    - value: 30

# Allow to reuse TIME-WAIT sockets for new connections when it is
# safe from protocol viewpoint. Default value is 0.
net.ipv4.tcp_tw_reuse:
  sysctl.present:
    - value: 1

# Enable fast recycling TIME-WAIT sockets. Default value is 0.
# !! Note: NAT problems with tcp_timestamps.
net.ipv4.tcp_tw_recycle:
  sysctl.present:
    - value: 0

# Maximal number of remembered connection requests.
net.ipv4.tcp_max_syn_backlog:
  sysctl.present:
    - value: 819200

# Send how many initial SYNs for an active TCP connection attempt.
# Each SYN will wait 30s before send another SYN.
# Default value is 5, which corresponds to ~180seconds.
net.ipv4.tcp_syn_retries:
  sysctl.present:
    - value: 2

# Send how many SYNACKs for a passive TCP connection attempt.
# Default value is 5, which corresponds to ~180seconds.
net.ipv4.tcp_synack_retries:
  sysctl.present:
    - value: 2

# How often TCP sends out keepalive messages when keepalive is enabled.
# Default: 7200 (2hours).
net.ipv4.tcp_keepalive_time:
  sysctl.present:
    - value: 1200

# Defines the local port range that is used by TCP and UDP to 
# choose the local port.
net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: 10240 61000
