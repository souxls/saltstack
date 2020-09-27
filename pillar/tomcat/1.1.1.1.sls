tomcat:
  1.1.1.1:
    test.test.com:
      tomcat_path: /web
      tomcat_version: 8.0.36
      servername: test1.test.com
      port: 9090
      jdk_path: /usr/local
      jdk_version: 1.8.0_60
      namingresource:
          jdbc: test
          dbname: test
          dbhost: 1.1.1.1:3306
          dbuser: test
          dbpassword: '123456'
    test1.test.com:
      tomcat_path: /web
      tomcat_version: 7.0.70
      servername: test2.test.com
      port: 9191
      jdk_path: /usr/local
      jdk_version: 1.7.0_80
    test2.test.com:
      tomcat_path: /web
      tomcat_version: 6.0.45
      servername: test3.test.com
      port: 9292
      jdk_path: /usr/local
      jdk_version: 1.6.0_45
    test4.test.com:
      tomcat_path: /web
      tomcat_version: 6.0.45
      servername: test4.test.com
      port: 9494
      jdk_path: /usr/local
      jdk_version: 1.6.0_45
