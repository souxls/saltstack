iptables:
  1.1.1.2:
    http80:
      table: filter
      chain: INPUT
      jump: ACCEPT
      source: '1.1.1.2/32'
      save: True
    http80:
      table: filter
      chain: INPUT
      jump: ACCEPT
      source: '10.2.45.75/32'
      save: True
    http8080:
      table: filter
      chain: INPUT
      jump: ACCEPT
      source: 1.1.1.1/32,1.1.1.2
      match: tcp
      proto: tcp
      dports: 80,8181
      save: True
