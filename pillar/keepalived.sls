keepalived:
  1.1.1.1:
    router_id: testtest
    state: MASTER
    interface: eth0
    virtual_router_id: 155
    priority: 150
    virtual_ipaddress: 1.0.0.1,2.2.2.2
