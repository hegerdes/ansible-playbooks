const yaml = require('js-yaml');
const fs = require('fs');
const util = require('util');
const jinja = require('nunjucks')

// Get ingress config
if(process.argv.length != 4){
  console.error('Invalid parameter count!')
  console.log(`Usage: ${process.argv[1]} <nginx|traefik> <ingress_file>` )
  process.exit(1)
}
let ingress_conf = process.argv[3] || 'ingress-hosts-nginx.yml'

let ingress
try {
  ingress = yaml.load(fs.readFileSync(process.cwd() + '/' + ingress_conf));
} catch (e) {
  console.error("Unable to read specified ingress file.\nPlease check path and format!\nError: " + e.message);
  process.exit(1)
}
if(process.env.USE_DOCKER)
  ingress.conf.nginx.use_docker = true;

console.log('Using the following ingress file:')
console.log(util.inspect(ingress, false, null, true))

async function generateNginxConf(){
let res = ''
  let conf_dst = `${__dirname}/nginx/conf.d`
  if (!fs.existsSync(conf_dst)){
    fs.mkdirSync(conf_dst);
}
  console.log('Generating nginx conf files...')
  for(site of ingress.sites){
    res = jinja.render(__dirname + '/nginx-site.conf.j2', { nginx_vhost: site, nginx_settings: ingress.conf.nginx });
    console.log(`Writing to ${conf_dst}/${site.host}.conf`)
    fs.writeFileSync(`${conf_dst}/${site.host}.conf`, res)
  }

  res = jinja.render(__dirname + '/my-entrypoint.sh.j2', { sites: ingress.sites, nginx_settings: ingress.conf.nginx, conf:ingress.conf.nginx });
  console.log(`Writing entrypoint to ${__dirname}/nginx/my-entrypoint.sh`)
  fs.writeFileSync(`${__dirname}/nginx/my-entrypoint.sh`, res)
  console.log('done')
}

async function run(){
  switch(process.argv[2]) {
    case 'nginx':
      await generateNginxConf()
      break;
    case 'traefik':
      // code block
      break;
    default:
      console.error('Target config not supported right now')
      process.exit(1)
  }
}

run()