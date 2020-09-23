# -*- coding: utf-8 -*-
'''
  salt custom state 
'''


def __virtual__():
    '''
    Only load if the lvs module is available in __salt__
    '''
    return 'lvs_server' if 'lvs.get_rules' in __salt__ else False


def present(name,
            protocol=None,
            service_address=None,
            server_address=None,
            packet_forward_method='dr',
            weight=1
           ):
    '''
    Ensure that the named service is present.
    name
        The LVS server name
    protocol
        The service protocol
    service_address
        The LVS service address
    server_address
        The real server address.
    packet_forward_method
        The LVS packet forwarding method(``dr`` for direct routing, ``tunnel`` for tunneling, ``nat`` for network access translation).
    weight
        The capacity  of a server relative to the others in the pool.
    .. code-block:: yaml
        lvsrs:
          lvs_server.present:
            - protocol: tcp
            - service_address: 1.1.1.1:80
            - server_address: 192.168.0.11:8080
            - packet_forward_method: dr
            - weight: 10
    '''
    ret = {'name': name,
           'changes': {},
           'result': True,
           'comment': ''}
