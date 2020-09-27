nginx:
  1.1.1.2: 
    test1.test.com:
      servername: test1.test.com,test.test.com
      upstream: 127.0.0.1:9090,127.0.0.1:9191
      location: ''
      ext:
        client_body_buffer_size 128k,
        proxy_buffer_size       8k,
        proxy_buffers           128 64k,
        proxy_busy_buffers_size 128k,
        proxy_temp_file_write_size 128k,
        proxy_ignore_client_abort on,
        proxy_connect_timeout   120,
        proxy_send_timeout      120,
        proxy_read_timeout      120
    test2.test.com:
      servername: test2.test.com
      upstream: 127.0.0.1:9292
      location: 
        location /aa {,
           deny all;,
        },
        location /bb {,
           deny all;,
           allow all;,
        }
      ext: ''
    cc.test.com:
      servername: cc.test.com
      location: ''
      upstream: ''
      ext: proxy_redirect off,proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for
    dd.test.com:
      servername: dd.test.com
      upstream: ''
      location: ''
      ext: ''
