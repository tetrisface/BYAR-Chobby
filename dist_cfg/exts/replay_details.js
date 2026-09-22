const path = require('path');

const { DemoParser } = require('sdfz-demo-parser');

const { bridge } = require('../spring_api');
const springPlatform = require('../spring_platform');
const { log } = require('../spring_log');

// Full replay setup (modoptions, start boxes, AIs) requested on demand, e.g.
// by Chobby's replay-list "Save preset" button. Unlike ReadReplayInfo this is
// a one-shot parse with no cache file, and it always replies so the Lua side
// can tell a parse failure (error reply) from a missing extension (timeout).
bridge.on('ReadReplayDetails', async command => {
	const relativePath = command.relativePath;
	try {
		const parser = new DemoParser({ skipPackets: true });
		const demo = await parser.parseDemo(path.join(springPlatform.writePath, relativePath));
		bridge.send('ReplayDetails', {
			relativePath: relativePath,
			gameSettings: demo.info.gameSettings,
			allyTeams: demo.info.allyTeams,
			ais: demo.info.ais,
		});
	} catch (err) {
		log.error(`ReadReplayDetails failed for ${relativePath}: ${err}`);
		bridge.send('ReplayDetails', {
			relativePath: relativePath,
			error: String(err),
		});
	}
});
