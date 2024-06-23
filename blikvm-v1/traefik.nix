{
  services.traefik = {
    enable = true;

    dynamicConfigOptions = {
      http.middlewares.redirect-to-https.redirectscheme = {
        scheme = "https";
        permanent = true;
      };
      http = {
        services = {
          pikvm.loadBalancer.servers = [ { url = "http://127.0.0.1:6969"; } ];
        };
        routers = {
          pikvm-insecure = {
            rule = "HostRegexp(`{any:.+}`) || ClientIP(`0.0.0.0/0`) || ClientIP(`::/0`)";
            entryPoints = [ "web" ];
            service = "pikvm";
            middlewares = "redirect-to-https";
          };
          pikvm = {
            rule = "HostRegexp(`{any:.+}`) || ClientIP(`0.0.0.0/0`) || ClientIP(`::/0`)";
            entryPoints = [ "websecure" ];
            service = "pikvm";
            tls = {};
          };
        };
      };
    };

    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      serversTransport.insecureSkipVerify = true;

      accessLog = true;
      log.level = "DEBUG";

      entryPoints.web.address = ":80";
      entryPoints.websecure.address = ":443";
    };
  };
}
