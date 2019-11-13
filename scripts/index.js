const PACKAGES = require('./packages').PACKAGES;
const INDEX_FILE = require('./index-v1.json');
const args = process.argv.slice(2);

module.exports.getPackageApkVersion = function(packageName) {
    // Index 0 is the latest version
    if (!!INDEX_FILE.packages[packageName]) {
        console.log(INDEX_FILE.packages[packageName][0].apkName);
    } else {
        console.log();
    }
}

module.exports.getApplicationName = function(index) {
    index < PACKAGES.length ? console.log(PACKAGES[index].name) : console.log();
}

module.exports.getApplicationPackageName = function(index) {
    index < PACKAGES.length ? console.log(PACKAGES[index].packageName) : console.log();
}

module.exports.getApplicationType = function(index) {
    index < PACKAGES.length ? console.log(PACKAGES[index].type) : console.log();
}
