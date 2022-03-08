const yaml = require("js-yaml");
const fs = require("fs");
const ejs = require("ejs");
const util = require("util");

// Get ingress config
if (process.argv.length != 4) {
  console.error("Invalid parameter count!");
  console.log(`Usage: ${process.argv[1]} <nginx|traefik> <ingress_file>`);
  process.exit(1);
}
let ingress_conf = process.argv[3] || "ingress-hosts-nginx.yml";

let ingress;
try {
  ingress = yaml.load(fs.readFileSync(process.cwd() + "/" + ingress_conf));
} catch (e) {
  console.error(
    "Unable to read specified ingress file.\nPlease check path and format!\nError: " +
    e.message
  );
  process.exit(1);
}
if (process.env.USE_DOCKER) ingress.conf.nginx.use_docker = true;

console.log("Using the following ingress file:");
console.log(util.inspect(ingress, false, null, true));

async function generateNginxConf() {
  let conf_dst = `${__dirname}/nginx/conf.d`;
  if (!fs.existsSync(conf_dst)) {
    fs.mkdirSync(conf_dst);
  }
  console.log("Generating nginx conf files...");
  for (let site of ingress.sites) {
    var res = await ejs.renderFile(
      __dirname + "/nginx-site.conf.ejs",
      { site: site, conf: ingress.conf.nginx },
      { async: true }
    );
    console.log(`Writing to ${conf_dst}/${site.host}.conf`);
    fs.writeFileSync(`${conf_dst}/${site.host}.conf`, res);
  }
  res = await ejs.renderFile(
    __dirname + "/my-entrypoint.sh.ejs",
    { sites: ingress.sites, conf: ingress.conf.nginx },
    { async: true }
  );
  console.log(`Writing entrypoint to ${__dirname}/nginx/my-entrypoint.sh`);
  fs.writeFileSync(`${__dirname}/nginx/my-entrypoint.sh`, res);
  console.log("done");
}

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
}

async function run() {
  switch (process.argv[2]) {
    case "nginx":
      await generateNginxConf();
      break;
    case "traefik":
      generateTraefikConf();
      break;
    default:
      console.error("Target config not supported right now");
      process.exit(1);
  }
}

run();
