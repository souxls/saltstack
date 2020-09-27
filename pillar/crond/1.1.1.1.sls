crond:
  1.1.1.1:
    ntpdate pool.ntp.org >/dev/null 2>&1:
      minute: '*/3'
    echo aa:
      minute: 3
