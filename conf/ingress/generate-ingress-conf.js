const yaml = require('js-yaml');
const fs = require('fs');
const ejs = require('ejs');
const util = require('util');

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
let conf_dst = `${__dirname}/nginx/conf.d`
  if (!fs.existsSync(conf_dst)){
    fs.mkdirSync(conf_dst);
}
  console.log('Generating nginx conf files...')
  for(site of ingress.sites){
    var res = await ejs.renderFile(__dirname + '/nginx-site.conf.ejs', {site:site, conf:ingress.conf.nginx}, {async: true})
    console.log(`Writing to ${conf_dst}/${site.host}.conf`)
    fs.writeFileSync(`${conf_dst}/${site.host}.conf`, res)
    // console.log(res)
  }
  var res = await ejs.renderFile(__dirname + '/certbot.ejs', {sites:ingress.sites, conf:ingress.conf.nginx}, {async: true})
  fs.writeFileSync(`${__dirname}/nginx/my-entrypoint.sh`, res)
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