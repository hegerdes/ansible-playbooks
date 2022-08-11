const fs = require('fs');
const net = require('net')
const util = require('util');
const yaml = require('js-yaml');
const jinja = require('nunjucks')

// ARGS check
if (process.argv.length != 4) {
  console.error("Invalid parameter count!");
  console.log(`Usage: ${process.argv[1]} <nginx|traefik> <ingress_file>`);
  process.exit(1);
}
let ingress_conf = process.argv[3] || "ingress-hosts-nginx.yml";

// Get ingress config
let ingress;
try {
  var filename = (ingress_conf[0] == "/") ? ingress_conf: process.cwd() + "/" + ingress_conf
  ingress = yaml.load(fs.readFileSync(filename));
} catch (e) {
  console.error(
    "Unable to read specified ingress file.\nPlease check path and format!\nError: " +
    e.message
  );
  process.exit(1);
}
console.log("Using the following ingress file:");
console.log(util.inspect(ingress, false, null, true));

async function createUpstreamHosts(){
  console.log('Generating upstream domain list...')
  var upstream_domains = []
  if(ingress.conf && ingress.conf.internal_extra_domains)
    upstream_domains = upstream_domains.concat(ingress.conf.internal_extra_domains)
  // Upstream domains
  for(let site of ingress.sites){
    if(site.upstreams){
      for(var upstream of site.upstreams){
        for(var target of upstream.targets){
          if(!net.isIP(target.split(':')[0])) upstream_domains.push(target.split(':')[0])
        }
      }
    }
    // Location domains
    if(site.nginx && site.nginx.locations){
      for(var location of site.nginx.locations){
        for(var line of location.body.split('\n')){
          if (line.includes("proxy_pass ")){
            var pass_target = line.trim().split(/(\s+)/).pop()
            var pass_domain = pass_target.split("//").pop().slice(0,-1)
            if(pass_domain.includes(":")){
              if(!net.isIP(pass_domain.split(':')[0])) upstream_domains.push(pass_domain.split(':')[0])
            }else{
              upstream_domains.push(pass_domain)

            }
            // if(pass_domain.match(is_domain)) console.log(pass_domain)
          }
        }
      }
    }
  }
  fs.writeFileSync(`${__dirname}/domain.list`, upstream_domains.join("\n") + "\n")
  console.log('Upstreams:', upstream_domains, "\ndone")
}

/**
 * Generate nginx conf and save it
 */
async function generateNginxConf(){
  let domains = [];
  let res = ''
  let conf_dst = `${__dirname}/nginx/conf.d`
  if (!fs.existsSync(conf_dst)) {
    fs.mkdirSync(conf_dst);
  }
  console.log('Generating nginx conf files...')
  for(let site of ingress.sites){
    domains.push(site.host)

    // copy common locations into site
    if (Object.prototype.hasOwnProperty.call(site, 'nginx') && Object.prototype.hasOwnProperty.call(site.nginx, 'common_locations')) {
      for(let i = 0; i < site.nginx.common_locations.length; i++) {
        let myLocation = Object.assign({}, ingress.conf.nginx.common_locations[site.nginx.common_locations[i].name]);
        if (Object.prototype.hasOwnProperty.call(site.nginx.common_locations[i], 'body_params')) {
          myLocation['body_params'] = site.nginx.common_locations[i].body_params;
        }
        else {
          myLocation['body_params'] = {};
        }
        if (!Object.prototype.hasOwnProperty.call(site.nginx, 'locations')) {
          site.nginx.locations = [];
        }
        site.nginx.locations.push(myLocation);
      }
    }

    // preprocess location body templates
    if (Object.prototype.hasOwnProperty.call(site, 'nginx') && Object.prototype.hasOwnProperty.call(site.nginx, 'locations')) {
      for(let i = 0; i < site.nginx.locations.length; i++) {
        if (Object.prototype.hasOwnProperty.call(site.nginx.locations[i], 'body_template')) {
          // TODO: check if body_params exists
          site.nginx.locations[i].body = jinja.renderString(site.nginx.locations[i].body_template, site.nginx.locations[i].body_params);
        }

        else if (Object.prototype.hasOwnProperty.call(site.nginx.locations[i], 'body_template_name')) {
          // TODO: check if ingress.conf.body_templates[site.locations[i].body_template_name] exists
          site.nginx.locations[i].body = jinja.renderString(ingress.conf.nginx.body_templates[site.nginx.locations[i].body_template_name], site.nginx.locations[i].body_params);
        }
      }
    }

    let template_file = (site.tls && site.tls === 'no') ? '/nginx-site-http-only.conf.j2' : '/nginx-site.conf.j2'
    if (!ingress.conf || !ingress.conf.nginx) ingress.conf = {nginx: {}}
    res = jinja.render(__dirname + template_file, { nginx_vhost: site, nginx_settings: ingress.conf.nginx });
    console.log(`Writing to ${conf_dst}/${site.host}.conf`)
    fs.writeFileSync(`${conf_dst}/${site.host}.conf`, res)
  }

  // Default site
  let create_default_server = (ingress.conf && ingress.conf.nginx && ingress.conf.nginx.create_default_server) ? ingress.conf.nginx.create_default_server : 'on'
  if(create_default_server == 'on' || create_default_server == 'yes' || create_default_server == 'true' ){
    res = jinja.render(__dirname + '/nginx-default-site.conf.j2', { sites: ingress.sites, nginx_settings:ingress.conf.nginx });
    fs.writeFileSync(`${__dirname}/nginx/conf.d/default.conf`, res)
    console.log(`Writing default site to ${__dirname}/nginx/conf.d/default.conf`)
  }
  fs.writeFileSync(`${__dirname}/nginx/conf.d/domains.info`, domains.join('\r\n'))
  console.log('done')
}

/**
 * Generate trafil conf and save it
 */
async function generateTraefikConf() {
  let traefik_conf = {
    global: { checkNewVersion: true, sendAnonymousUsage: false },
    log: { level: "DEBUG", format: "json" },
    accessLog: { format: "json" },
    entryPoints: {
      web: { address: ":80" },
      websecure: { address: ":443" }
    },
    providers: {
      file: { directory: "/srv/traefik/hosts", watch: true }
    },
    metrics: {
      prometheus: {
        addEntryPointsLabels: true,
        addServicesLabels: true,
      },
    },
    certificatesResolvers: {
      traefik_ssl_resolver: {
        acme: {
          email: "info@gmail.com",
          storage: "/srv/traefik/tls",
          httpChallenge: {
            entryPoint: "web"
          }
        }
      }
    },
  };
  // Overall structure
  let traefik_hosts = {
    http: { routers: {}, services: {}, middlewares: {} },
    tcp: { routers: {}, services: {} },
  };

  if (
    ingress.conf &&
    ingress.conf.traefik &&
    ingress.conf.traefik.middlewares
  ) {
    traefik_hosts.http.middlewares = ingress.conf.traefik.middlewares;
  }

  // For every site
  var uppstream_targets = [];
  for (let site of ingress.sites) {
    let service_name = site.host.split(".")[0];
    if (site.traefik && site.traefik.protocol == "tcp") {
      // Create routers
      traefik_hosts.tcp.routers = {
        ...traefik_hosts.tcp.routers,
        [service_name]: {
          entryPoints: ["web", "websecure"],
          service: service_name,
          rule: "Host(`" + site.host + "`)",
        },
      };
      // TLS check
      if (!site.tls || site.tls === "no") {
        traefik_hosts.tcp.routers[service_name] = {
          ...traefik_hosts.tcp.routers[service_name],
          certresolver: "traefik_ssl_resolver",
        };
      }
      // Init upstream array
      uppstream_targets = [];
      for (let upstearm of site.upstreams) {
        uppstream_targets.push({ address: upstearm });
      }
      traefik_hosts.tcp.services = {
        ...traefik_hosts.tcp.services,
        [service_name]: { loadBalancer: { servers: uppstream_targets } },
      };
    } else {
      traefik_hosts.http.routers = {
        ...traefik_hosts.http.routers,
        [service_name]: {
          entryPoints: ["web", "websecure"],
          service: service_name,
          rule: "Host(`" + site.host + "`)",
          middlewares: [],
        },
      };
      // Middlewares check
      if (site.traefik && site.traefik.middlewares) {
        traefik_hosts.http.routers[service_name].middlewares =
          site.traefik.middlewares;
      }
      // TLS check
      if (!site.tls || site.tls === "no") {
        traefik_hosts.http.routers[service_name] = {
          ...traefik_hosts.http.routers[service_name],
          certresolver: "traefik_ssl_resolver",
        };
      }
      // Init upstream array
      uppstream_targets = [];
      for (let upstearm of site.upstreams) {
        uppstream_targets.push({ url: "http://" + upstearm });
      }
      traefik_hosts.http.services = {
        ...traefik_hosts.http.services,
        [service_name]: { loadBalancer: { servers: uppstream_targets } },
      };
    }
  }
  console.log(util.inspect(traefik_hosts, false, null, true));
  console.log(yaml.dump(traefik_hosts));
  console.log(yaml.dump(traefik_conf));
}

// Start
async function run() {
  switch (process.argv[2]) {
    case "nginx":
      await generateNginxConf();
      break;
    case "traefik":
      generateTraefikConf();
      break;
    case "upstream-domains":
      createUpstreamHosts();
      break;
    default:
      console.error("Target config not supported right now");
      process.exit(1);
  }
}

run();
