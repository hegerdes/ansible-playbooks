var https = require("https");

console.log("Starting snapshot script...")
const snapshoptsToAlwaysKeep = [];
const costPerGB = 0.0119;
const imagesToKeep_default = {
    daily: 3,
    weekly: 3,
    monthly: 3,
    yearly: 3,
}
var imagesToKeep
var options = {
    method: "GET",
    hostname: "api.hetzner.cloud",
    headers: {
        Authorization: "Bearer " + process.env.HETZNER_API_KEY,
    },
};

if (process.env.HETZNER_API_KEY == null) {
    console.error('No API token given! Exit')
    process.exit(1)
}

try {
    imagesToKeep = JSON.parse(process.env.KEEP_SETTINGS)
} catch (err) {
    console.error("Unable to parse image keep settings.\nFallback to defaults:")
}

if (!imagesToKeep) {
    imagesToKeep = imagesToKeep_default
}

// sleep helper
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Make http reqest
function makeRequest(options, payload = null) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            var chunks = [];
            res.on("data", function (chunk) {
                chunks.push(chunk);
            });
            res.on("end", function (_chunk) {
                if (chunks.length > 0) {
                    resolve(JSON.parse(Buffer.concat(chunks).toString()));
                } else {
                    resolve({ status: res.statusCode });
                }
            });
            req.on("error", (err) => {
                console.error(err)
                reject(err);
            });
        });
        if (payload) {
            req.write(payload)
        }
        req.end();
    });
}

// Delete every image in images
function deleteSnapshotImages(images) {
    let requests = [];
    for (var image of images) {
        if (image.description in snapshoptsToAlwaysKeep) continue
        var delete_image_request_options = {
            ...options,
            method: "DELETE",
            path: "/v1/images/" + image.id,
        };
        requests.push(makeRequest(delete_image_request_options));
    }
    return Promise.all(requests);
}

// Makes image creation API request for given label
function createSnapshotImages(servers, labels = {}) {
    let requests = [];
    for (var server of servers) {
        var create_snaphot_request_options = {
            ...options,
            method: "POST",
            path: "/v1/servers/" + server.id + "/actions/create_image",
            headers: {
                "Authorization": options.headers.Authorization,
                "Content-Type": "application/json",
            },
        };
        var description_labels = ""
        if (Object.keys(labels).length !== 0) {
            description_labels = Object.keys(labels).toString().replace(",", "-") + "-"
        }
        var payload = {
            description: new Date().toISOString().split("T")[0] + "-" + description_labels + server.name,
            type: "snapshot",
            labels: {
                date: new Date().toISOString().split("T")[0],
                host: server.name,
                automatic: "true",
                ...labels
            },
        }
        requests.push(makeRequest(create_snaphot_request_options, JSON.stringify(payload)));
    }
    return Promise.all(requests);
}

// Creates one or more snapshots for every server given
async function createAllSnapshotImages(servers) {
    var today = new Date();
    var createdImages = []
    var res = []

    // Wait till previous images are created
    await waitForImageCreation()

    // Only on Jan first
    if (today.getDate() === 1 && today.getMonth() === 1) {
        console.log("Creating yearly...")
        res = await createSnapshotImages(servers, { yearly: "true" })
        res.forEach(img => createdImages.push(img))
        await waitForImageCreation()
    }
    // Only on first of month
    if (today.getDate() === 1) {
        console.log("Creating monthly...")
        res = await createSnapshotImages(servers, { monthly: "true" })
        res.forEach(img => createdImages.push(img))
        await waitForImageCreation()
    }
    // Only on sunday
    if (today.getDay() === 0) {
        console.log("Creating weekly...")
        res = await createSnapshotImages(servers, { weekly: "true" })
        res.forEach(img => createdImages.push(img))
        await waitForImageCreation()
    }

    // Dailies
    console.log("Creating daily...")
    var dailys = await createSnapshotImages(servers, { daily: "true" })
    dailys.forEach(img => createdImages.push(img))
    await waitForImageCreation()

    for (let response of createdImages) {
        if ('error' in response) {
            console.error("Error with API call! Exit")
            console.error("API response:", createdImages)
            process.exit(1)
        }
    }
    return createdImages
}

// Lists all servers with persistent label
function getServers() {
    return { ...options, path: "/v1/servers?label_selector=persistent" };
}

// Only one image per time can be created.
// Wait till it is done
async function waitForImageCreation() {
    var snapshots = await getImages(null, "creating")
    var err_counter = 0;

    while (snapshots.length != 0) {
        console.log("Waiting for image creation...");
        await sleep(15000);
        try {
            snapshots = await getImages(null, "creating");
        }catch(err){
            err_counter += 1;
            console.error("Error making http request: " + err.massage);
            await sleep(15000);
            if(err_counter > 3) process.exit(1);
        }
    }
}

// Get all images with set satus or label
// No label given gets all (automatic generated) images
async function getImages(label = null, status = "available") {
    label = (label) ? "&label_selector=" + label : ""
    var images_request_options = {
        ...options,
        path: "/v1/images?type=snapshot&label_selector=automatic&status=" + status + "&sort=created:desc" + label,
    };
    return (await makeRequest(images_request_options)).images;
}

async function run() {
    console.log("Settings for images to retain:", imagesToKeep)
    var totalBackupSize = 0;
    var toDelete = []
    var all_snapshots = []

    var persistent_servers = await makeRequest(getServers());
    if (persistent_servers.servers === undefined) {
        console.log('No servers to operate on')
        process.exit(1)
    }
    persistent_servers.servers.forEach(server => { console.log("Found the persistent server: " + server.name) })
    var numOfServers = persistent_servers.servers.length

    var created_images = await createAllSnapshotImages(persistent_servers.servers)
    console.log("Created images:", created_images)

    var snapshots = []
    snapshots = await getImages("daily")
    all_snapshots.push(...snapshots)
    snapshots.forEach(snap => { totalBackupSize += snap.image_size })
    snapshots.slice(numOfServers * imagesToKeep.daily).forEach(img => { toDelete.push(img) })

    snapshots = await getImages("weekly")
    all_snapshots.push(...snapshots)
    snapshots.forEach(snap => { totalBackupSize += snap.image_size })
    snapshots.slice(numOfServers * imagesToKeep.weekly).forEach(img => { toDelete.push(img) })

    snapshots = await getImages("monthly")
    all_snapshots.push(...snapshots)
    snapshots.forEach(snap => { totalBackupSize += snap.image_size })
    snapshots.slice(numOfServers * imagesToKeep.monthly).forEach(img => { toDelete.push(img) })

    snapshots = await getImages("yearly")
    all_snapshots.push(...snapshots)
    snapshots.forEach(snap => { totalBackupSize += snap.image_size })
    snapshots.slice(numOfServers * imagesToKeep.yearly).forEach(img => { toDelete.push(img) })

    console.log("Stored Snapshots:")
    all_snapshots.forEach(snap => { console.log(`${snap.id} - ${snap.description} created from ${snap.created_from.name} (${snap.created_from.id}) - size ${snap.image_size.toFixed(2)} GB`) })
    console.log("Approximate costs: " + (totalBackupSize * costPerGB).toFixed(2) + "€");

    console.log("Will delete:")
    toDelete.forEach(image => console.log(image.description + " created on: " + image.created))
    await deleteSnapshotImages(toDelete);
}

run();

