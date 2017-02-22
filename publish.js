const PublishRelease = require( 'publish-release' );
const ProgressBar = require( 'progress' );
const fs = require( 'fs' );
const path = require( 'path' );
const package = require( './package.json' );

const DIR = './deploy';
const UPLOAD = './deploy/blog-in-a-box.zip';

// http://stackoverflow.com/questions/15696218/get-the-most-recent-file-in-a-directory-node-js
function getNewestFile( dir, regexp ) {
    let newest = null, files = fs.readdirSync(dir), one_matched = 0, i

    for (i = 0; i < files.length; i++) {

        if (regexp.test(files[i]) == false)
            continue
        else if (one_matched == 0) {
            newest = files[i];
            one_matched = 1;
            continue
        }

        f1_time = fs.statSync(path.join(dir, files[i])).mtime.getTime()
        f2_time = fs.statSync(path.join(dir, newest)).mtime.getTime()
        if (f1_time > f2_time)
            newest[i] = files[i]
    }

    if (newest != null)
        return (path.join(dir, newest))
    return null
}

function publishIt( stat, cb ) {
	let last = 0;
	const bar = new ProgressBar( '[:bar] :percent time remaining :etas', {
		complete: '=',
		incomplete: ' ',
		width: 20,
		total: stat.size
	} );

	const publish = PublishRelease( {
		token: process.env.GH_TOKEN,
		owner: 'tinkertinker',
		repo: 'biab-raspbian',
		tag: 'v' + package.version,
		name: 'Release v' + package.version,
		notes: '',
		draft: true,
		prerelease: false,
		reuseRelease: true,
		reuseDraftOnly: true,
		assets: [ UPLOAD ],
	}, cb );

	publish.on( 'upload-asset', name => {
		console.log( 'Uploading ' + name + ' v' + package.version );
	} );

	publish.on( 'upload-progress', ( name, progress ) => {
		bar.tick( progress.transferred - last );
		last = progress.transferred;
	} );
}

if ( process.env.GH_TOKEN ) {
	const latest = getNewestFile( './deploy', new RegExp( '\.zip$' ) );

	if ( latest !== UPLOAD ) {
		fs.renameSync( latest, UPLOAD );
	}

	const fileStat = fs.statSync( UPLOAD );

	publishIt( fileStat, ( err, release ) => {
		if ( err ) {
			console.error( err );
			process.exit( 1 );
		}

		console.log( '' );
		console.log( 'Published to: ' + release.url );
	} );
} else {
	console.error( 'Set environment variable GH_TOKEN to an application specific password' );
}
