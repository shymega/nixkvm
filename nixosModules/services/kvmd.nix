{ config, pkgs, ... }:
{

  services.nginx = {
    enable = true;
    upstreams = {
      ustreamer.servers = {
        "unix:/run/kvmd/ustreamer.sock" = {
          fail_timeout = "0s";
          max_fails = "0";
        };
      };
      kvmd.servers = {
        "unix:/run/kvmd/kvmd.sock" = {
          fail_timeout = "0s";
          max_fails = "0";
        };
      };
      janus-ws.servers = {
        "unix:/run/kvmd/janus-ws.sock" = {
          fail_timeout = "0s";
          max_fails = "0";
        };
      };
    };
    virtualHosts."localhost" = {
      #addSSL = true;
      #enableACME = true;
      default = true;
      listen = [{
        addr = "127.0.0.1";
        port = 6969;
      }];
      extraConfig = ''
        absolute_redirect off;
        
        index index.html;
        
        auth_request /auth_check;
        
        location = /auth_check {
        	internal;
        	proxy_pass http://kvmd/auth/check;
        	proxy_pass_request_body off;
        	proxy_set_header Content-Length "";
        	auth_request off;
        }
        
        location / {
        	root ${pkgs.kvmd}/share/web;
        	include ${pkgs.kvmd}/share/nginx/loc-login.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-nocache.conf;
        }
        
        location @login {
        	return 302 /login;
        }
        
        location /login {
        	root ${pkgs.kvmd}/share/web;
        	auth_request off;
        }
        
        location /share {
        	root ${pkgs.kvmd}/share/web;
        	include ${pkgs.kvmd}/share/nginx/loc-nocache.conf;
        	auth_request off;
        }
        
        location = /share/css/user.css {
        	alias ${pkgs.kvmd}/share/web.css;
        	auth_request off;
        }
        
        location = /favicon.ico {
        	alias ${pkgs.kvmd}/share/web/favicon.ico;
        	include ${pkgs.kvmd}/share/nginx/loc-nocache.conf;
        	auth_request off;
        }
        
        location = /robots.txt {
        	alias ${pkgs.kvmd}/share/web/robots.txt;
        	include ${pkgs.kvmd}/share/nginx/loc-nocache.conf;
        	auth_request off;
        }
        
        location /api/ws {
        	rewrite ^/api/ws$ /ws break;
        	rewrite ^/api/ws\?(.*)$ /ws?$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-websocket.conf;
        	auth_request off;
        }
        
        location /api/hid/print {
        	rewrite ^/api/hid/print$ /hid/print break;
        	rewrite ^/api/hid/print\?(.*)$ /hid/print?$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-bigpost.conf;
        	auth_request off;
        }
        
        location /api/msd/read {
        	rewrite ^/api/msd/read$ /msd/read break;
        	rewrite ^/api/msd/read\?(.*)$ /msd/read?$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-nobuffering.conf;
        	proxy_read_timeout 7d;
        	auth_request off;
        }
        
        location /api/msd/write_remote {
        	rewrite ^/api/msd/write_remote$ /msd/write_remote break;
        	rewrite ^/api/msd/write_remote\?(.*)$ /msd/write_remote?$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-nobuffering.conf;
        	proxy_read_timeout 7d;
        	auth_request off;
        }
        
        location /api/msd/write {
        	rewrite ^/api/msd/write$ /msd/write break;
        	rewrite ^/api/msd/write\?(.*)$ /msd/write?$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-bigpost.conf;
        	auth_request off;
        }
        
        location /api/log {
        	rewrite ^/api/log$ /log break;
        	rewrite ^/api/log\?(.*)$ /log?$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-nobuffering.conf;
        	proxy_read_timeout 7d;
        	auth_request off;
        }
        
        location /api {
        	rewrite ^/api$ / break;
        	rewrite ^/api/(.*)$ /$1 break;
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	auth_request off;
        }
        
        location /streamer {
        	rewrite ^/streamer$ / break;
        	rewrite ^/streamer\?(.*)$ ?$1 break;
        	rewrite ^/streamer/(.*)$ /$1 break;
        	proxy_pass http://ustreamer;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-nobuffering.conf;
        }
        
        location /redfish {
        	proxy_pass http://kvmd;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	auth_request off;
        }

        location /janus/ws {
        	rewrite ^/janus/ws$ / break;
        	rewrite ^/janus/ws\?(.*)$ /?$1 break;
        	proxy_pass http://janus-ws;
        	include ${pkgs.kvmd}/share/nginx/loc-proxy.conf;
        	include ${pkgs.kvmd}/share/nginx/loc-websocket.conf;
        }
        
        location = /share/js/kvm/janus.js {
        	alias ${pkgs.janus-gateway.doc}/share/janus/javascript/janus.js;
        	include ${pkgs.kvmd}/share/nginx/loc-nocache.conf;
        }
        
        location = /share/js/kvm/adapter.js {
        	alias ${pkgs.janus-gateway.doc}/share/janus/javascript/adapter.js;
        	include ${pkgs.kvmd}/share/nginx/loc-nocache.conf;
        }
      '';
    };
  };

  users.users.nginx.extraGroups = [ "kvmd" "kvmd-janus" ];

  users.users.kvmd = {
    isSystemUser = true;
    group = "kvmd";
    extraGroups = [
      "kvmd"
      "gpio"  # for /dev/gpiochip*
      "video" # for /dev/cec*
    ];
  };
  users.groups.kvmd = {};

  security.sudo.extraConfig = ''
    kvmd ALL=(ALL) NOPASSWD: ${pkgs.kvmd}/bin/kvmd-helper-otgmsd-remount
  '';

  systemd.services.kvmd = {
    description = "PiKVM - The main daemon";
    after = [ "network.target" "network-online.target" "nss-lookup.target" ];
    serviceConfig = {
      User = "kvmd";
      Group = "kvmd";
      Type = "simple";
      Restart = "always";
      RestartSec = 3;
      AmbientCapabilities = "CAP_NET_RAW";

      ExecStart = "${pkgs.kvmd}/bin/kvmd --run";
      ExecStopPost = "${pkgs.kvmd}/bin/kvmd-cleanup --run";
      TimeoutStopSec = 10;
      KillMode = "mixed";
    };
    wantedBy = [ "multi-user.target" ];
  };
}

