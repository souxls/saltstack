iptables:
  10.3.246.99:
    http80:
      table: filter
      chain: INPUT
      jump: ACCEPT
      source: '10.3.246.65/32'
      save: True
    http8080:
      table: filter
      chain: INPUT
      jump: ACCEPT
      source: 10.3.246.99/32,10.3.246.65
      match: tcp
      proto: tcp
      dports: 80,8181
      save: True
